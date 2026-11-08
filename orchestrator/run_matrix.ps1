<#
.SYNOPSIS
    Matrix Orchestrator — Staged execution controller for the KI-Manager Evaluation Benchmark.

.DESCRIPTION
    Automates staged rollout across 162 matrix runs:
    - Stage 0: Smoke Test (gemini-2.5-flash, Task 1, Baseline vs KI)
    - Stage 1: Tier 3 Budget Models (Claude Haiku 5.5, GPT-5.6 Luna, Gemini 2.5 Flash)
    - Stage 2: Tier 2 Mid-Tier Models (Gemini 3.8 Flash, DeepSeek v4.1 Flash, Qwen 2.5 Coder 32B)
    - Stage 3: Tier 1 Flagship Models (GPT-5.6 Sol, Claude Sonnet 4, Gemini 4 Argon)
    
    Safety guardrails:
    - Enforces financial circuit breaker ($80.00 hard limit)
    - Implements exponential backoff on transient API failures
    - Persists matrix execution state and progress tracking

.PARAMETER Stage
    Execution stage to run: "smoke", "tier3", "tier2", "tier1", or "all".
.PARAMETER BudgetLimit
    Total expenditure threshold in USD that triggers the circuit breaker (default: 80.00).
.PARAMETER MaxRetries
    Maximum retry attempts on transient network or rate-limit failures (default: 3).
.PARAMETER ResultsDir
    Directory relative to repo root where artifacts are saved (default: "results").
.PARAMETER DryRun
    Simulate matrix execution without starting containers or making API calls.
#>

[CmdletBinding()]
param(
    [ValidateSet("smoke", "tier3", "tier2", "tier1", "all")]
    [string]$Stage = "smoke",
    [double]$BudgetLimit = 80.00,
    [int]$MaxRetries = 3,
    [string]$ResultsDir = "results",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path "$ScriptDir\..").Path
$RunnerScript = Join-Path $ScriptDir "benchmark_runner.ps1"
$VenvPy = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$ResultsPath = Join-Path $RepoRoot $ResultsDir
$MatrixStateFile = Join-Path $ResultsPath "matrix_state.json"

if (-not (Test-Path $ResultsPath)) {
    New-Item -ItemType Directory -Path $ResultsPath -Force | Out-Null
}

# --- Model Definitions by Tier ---
$Tier3Models = @(
    "anthropic/claude-haiku-5.5",
    "openai/gpt-5.6-luna",
    "google/gemini-2.5-flash"
)

$Tier2Models = @(
    "google/gemini-3.8-flash",
    "deepseek/deepseek-v4.1-flash",
    "qwen/qwen-2.5-coder-32b-instruct"
)

$Tier1Models = @(
    "openai/gpt-5.6-sol",
    "anthropic/claude-sonnet-4.5",
    "google/gemini-4-argon"
)

# --- Build Run Plan Based on Stage ---
$Runs = @()

function Add-MatrixRuns([string[]]$models, [string[]]$tasks, [string[]]$modes, [int[]]$attempts) {
    $plan = @()
    foreach ($model in $models) {
        foreach ($task in $tasks) {
            foreach ($mode in $modes) {
                foreach ($att in $attempts) {
                    $plan += [PSCustomObject]@{
                        Model = $model
                        Task = $task
                        Mode = $mode
                        Attempt = $att
                    }
                }
            }
        }
    }
    return $plan
}

switch ($Stage) {
    "smoke" {
        $Runs += [PSCustomObject]@{ Model = "google/gemini-2.5-flash"; Task = "task1"; Mode = "baseline"; Attempt = 1 }
        $Runs += [PSCustomObject]@{ Model = "google/gemini-2.5-flash"; Task = "task1"; Mode = "ki"; Attempt = 1 }
    }
    "tier3" {
        $Runs += Add-MatrixRuns $Tier3Models @("task1", "task2", "task3") @("baseline", "ki") @(1, 2, 3)
    }
    "tier2" {
        $Runs += Add-MatrixRuns $Tier2Models @("task1", "task2", "task3") @("baseline", "ki") @(1, 2, 3)
    }
    "tier1" {
        $Runs += Add-MatrixRuns $Tier1Models @("task1", "task2", "task3") @("baseline", "ki") @(1, 2, 3)
    }
    "all" {
        $Runs += Add-MatrixRuns ($Tier3Models + $Tier2Models + $Tier1Models) @("task1", "task2", "task3") @("baseline", "ki") @(1, 2, 3)
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [MATRIX ORCHESTRATOR] Stage: $Stage" -ForegroundColor Cyan
Write-Host " [MATRIX ORCHESTRATOR] Scheduled Runs: $($Runs.Count)" -ForegroundColor Cyan
Write-Host " [MATRIX ORCHESTRATOR] Budget Guard  : `$$BudgetLimit USD" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

function Get-CumulativeCost {
    $cost = 0.0
    $sessions = Get-ChildItem -Path $ResultsPath -Recurse -Filter "pi_session.jsonl" -ErrorAction SilentlyContinue
    foreach ($sf in $sessions) {
        if ($sf.Length -gt 0) {
            try {
                $lines = [System.IO.File]::ReadAllLines($sf.FullName)
                foreach ($l in $lines) {
                    if ($l -match '"cost":\s*\{.*?"total":\s*([0-9.]+)') {
                        $cost += [double]$Matches[1]
                    }
                }
            } catch {}
        }
    }
    return [math]::Round($cost, 4)
}

$completedCount = 0
$failedCount = 0

for ($i = 0; $i -lt $Runs.Count; $i++) {
    $r = $Runs[$i]
    $stepNum = $i + 1
    $runId = "$($r.Task)_$($r.Mode)_$($r.Model -replace '[^a-zA-Z0-9]','_')_att$($r.Attempt)"
    $runArtifacts = Join-Path $ResultsPath $runId
    $runMetaFile = Join-Path $runArtifacts "run_meta.json"

    Write-Host "`n>>> [RUN $stepNum/$($Runs.Count)] $runId" -ForegroundColor Yellow

    # Skip already completed successful runs
    if (Test-Path $runMetaFile) {
        try {
            $meta = Get-Content $runMetaFile -Raw | ConvertFrom-Json
            $code = if ($null -ne $meta.exit_code) { [int]$meta.exit_code } else { 0 }
            if ($code -eq 0 -and -not $meta.timed_out -and (Test-Path (Join-Path $runArtifacts "grade.json"))) {
                Write-Host "    -> Already completed successfully. Skipping." -ForegroundColor DarkGray
                $completedCount++
                continue
            }
        } catch {}
    }

    # Circuit Breaker Verification
    $currentCost = Get-CumulativeCost
    Write-Host "    -> Current Cumulative Spend: `$$currentCost USD (Threshold: `$$BudgetLimit)" -ForegroundColor Gray
    if ($currentCost -ge $BudgetLimit) {
        Write-Host "`n[CIRCUIT BREAKER TRIGGERED] Cumulative spend (`$$currentCost) has reached or exceeded `$$BudgetLimit!" -ForegroundColor Red
        Write-Host "Halting matrix execution immediately to protect budget." -ForegroundColor Red
        exit 80
    }

    # Execute with Retries & Exponential Backoff
    $retry = 0
    $success = $false
    while ($retry -lt $MaxRetries -and -not $success) {
        if ($retry -gt 0) {
            $backoffSeconds = 15 * [math]::Pow(2, $retry - 1)
            Write-Host "    -> Retry #$retry after ${backoffSeconds}s backoff..." -ForegroundColor Yellow
            Start-Sleep -Seconds $backoffSeconds
        }

        try {
            $runnerArgs = @(
                "-Model", "`"$($r.Model)`"",
                "-Task", "`"$($r.Task)`"",
                "-Mode", "`"$($r.Mode)`"",
                "-Attempt", "$($r.Attempt)",
                "-ResultsDir", "`"$ResultsDir`""
            )
            if ($DryRun) { $runnerArgs += "-DryRun" }

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RunnerScript @runnerArgs
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                $completedCount++
            } else {
                Write-Host "    WARNING: Runner exited with code $LASTEXITCODE." -ForegroundColor Yellow
                $retry++
            }
        } catch {
            Write-Host "    ERROR during run execution: $_" -ForegroundColor Red
            $retry++
        }
    }

    if (-not $success) {
        $failedCount++
        Write-Host "    FAILED run $runId after $MaxRetries attempts." -ForegroundColor Red
    }

    # Update Matrix State Snapshot
    $state = @{
        stage = $Stage
        total_runs = $Runs.Count
        completed = $completedCount
        failed = $failedCount
        cumulative_cost_usd = Get-CumulativeCost
        last_updated = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($MatrixStateFile, $state, (New-Object System.Text.UTF8Encoding $false))

    # Automatically update CSV summaries and Markdown report on the fly
    try {
        & $VenvPy (Join-Path $RepoRoot "analysis\evaluate_results.py") --input-dir $ResultsPath --output-dir (Join-Path $ResultsPath "summary") 2>$null
    } catch {}
}

$finalCost = Get-CumulativeCost
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " [MATRIX ORCHESTRATOR] Stage '$Stage' Execution Complete" -ForegroundColor Green
Write-Host " [MATRIX ORCHESTRATOR] Completed: $completedCount | Failed: $failedCount" -ForegroundColor Green
Write-Host " [MATRIX ORCHESTRATOR] Final Cost: `$$finalCost USD" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

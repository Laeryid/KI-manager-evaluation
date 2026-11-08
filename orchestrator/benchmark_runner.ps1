<#
.SYNOPSIS
    Benchmark Runner — Single-run execution pipeline for the KI-Manager Evaluation Benchmark.

.DESCRIPTION
    Manages complete lifecycle of one evaluated agent run:
    - Creates isolated ephemeral workspace outside parent repository
    - Configures A/B testing modes (Baseline vs KI-Enabled with StreamableHTTP supergateway)
    - Executes Pi agent in sandboxed Docker container with hard timeout watcher
    - Extracts clean git diff and persists telemetry
    - Injects hidden evaluation tests post-run to grade solution and regression integrity
    - Enforces deterministic process and container cleanup in finally block

.PARAMETER Model
    The OpenRouter model identifier (default: "google/gemini-2.5-flash").
.PARAMETER Task
    Benchmark task to evaluate: "task1", "task2", or "task3".
.PARAMETER Mode
    Evaluation mode: "baseline" or "ki".
.PARAMETER Attempt
    Attempt number (1, 2, or 3) for statistical replication.
.PARAMETER TimeoutSeconds
    Hard execution timeout in seconds (default: 1200 / 20 minutes).
.PARAMETER ResultsDir
    Directory relative to repo root where artifacts are saved (default: "results").
.PARAMETER TempRoot
    Root directory for ephemeral workspaces (default: "C:\Experiments\ki_benchmark_runs").
.PARAMETER KeepTemp
    Preserve temporary workspace for manual inspection.
.PARAMETER DryRun
    Simulate execution without starting Docker or calling OpenRouter APIs.
#>

[CmdletBinding()]
param(
    [string]$Model = "google/gemini-2.5-flash",
    [ValidateSet("task1", "task2", "task3")]
    [string]$Task = "task1",
    [ValidateSet("baseline", "ki")]
    [string]$Mode = "baseline",
    [int]$Attempt = 1,
    [int]$TimeoutSeconds = 1200,
    [string]$ResultsDir = "results",
    [string]$TempRoot = "C:\Experiments\ki_benchmark_runs",
    [string]$Thinking = "",
    [switch]$KeepTemp,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# --- 1. Path Resolution & Setup ---
$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path "$ScriptDir\..").Path
$TargetRepo = Join-Path $RepoRoot "target_repo"
$TasksDir = Join-Path $RepoRoot "tasks"
$VenvPy = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$KiVenvPy = "C:\Experiments\KI-base\.venv\Scripts\python.exe"
$DockerScript = "C:\Users\hp\.local\bin\docker.ps1"

# Safe normalized ID for directories and containers
$ModelNorm = $Model -replace '[^a-zA-Z0-9]', '_'
$RunId = "${Task}_${Mode}_${ModelNorm}_att${Attempt}"
$ContainerName = "pi-$RunId"
$ArtifactsDir = Join-Path $RepoRoot (Join-Path $ResultsDir $RunId)
$RunDir = Join-Path $TempRoot "run_$RunId"
$AgentDir = Join-Path $TempRoot "agent_$RunId"
$EmptyExtFile = Join-Path $TempRoot "empty_ext.txt"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [RUNNER] Run ID       : $RunId" -ForegroundColor Cyan
Write-Host " [RUNNER] Task         : $Task | Mode: $Mode | Attempt: $Attempt" -ForegroundColor Cyan
Write-Host " [RUNNER] Model        : $Model" -ForegroundColor Cyan
Write-Host " [RUNNER] Artifacts Dir: $ArtifactsDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Load .env from repository root if present
$envFile = Join-Path $RepoRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '^([^#=]+)=(.*)$' } | ForEach-Object {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($key, $val, "Process")
    }
}

if (-not $DryRun -and [string]::IsNullOrWhiteSpace($env:OPENROUTER_API_KEY)) {
    throw "OPENROUTER_API_KEY environment variable is not set."
}

if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir -Force | Out-Null
}

function Get-FreePort([int]$startPort = 3005) {
    $port = $startPort
    while ($port -lt 3999) {
        $inUse = $false
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("127.0.0.1", $port)
            $tcp.Close()
            $inUse = $true
        } catch {
            $inUse = $false
        }
        if (-not $inUse) { return $port }
        $port++
    }
    throw "No free TCP port found in range 3005-3999."
}

$sgProcess = $null
$startTime = Get-Date
$timedOut = $false
$containerExitCode = -1

try {
    # Ensure TempRoot exists
    if (-not (Test-Path $TempRoot)) {
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    }
    if (-not (Test-Path $EmptyExtFile)) {
        [System.IO.File]::WriteAllText($EmptyExtFile, "")
    }

    # Clean pre-existing ephemeral directories
    if (Test-Path $RunDir) { Remove-Item -Path $RunDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $AgentDir) { Remove-Item -Path $AgentDir -Recurse -Force -ErrorAction SilentlyContinue }

    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $AgentDir "sessions") -Force | Out-Null

    # Write Pi settings with hardened retry policy and backoff
    $piSettings = @{
        retry = @{
            enabled = $true
            maxRetries = 5
            baseDelayMs = 3000
            maxAgentDelayMs = 60000
            provider = @{
                timeoutMs = 300000
                maxRetries = 3
                maxRetryDelayMs = 60000
            }
        }
    } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText((Join-Path $AgentDir "settings.json"), $piSettings, (New-Object System.Text.UTF8Encoding $false))

    # --- 2. Copy Target Repository & Unpack Git ---
    Write-Host "  -> Copying pristine target repository to sandbox..." -ForegroundColor Gray
    Get-ChildItem -Path $TargetRepo -Exclude @(".git.zip", ".ki-base", ".serena") | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $RunDir -Recurse -Force
    }

    $gitZip = Join-Path $TargetRepo ".git.zip"
    if (Test-Path $gitZip) {
        Write-Host "  -> Extracting clean .git database..." -ForegroundColor Gray
        & $VenvPy -c "import zipfile; zipfile.ZipFile(r'$gitZip').extractall(r'$RunDir')"
    }

    # Ensure clean git state on pristine rich with strict LF line endings
    Push-Location $RunDir
    try {
        & git config core.autocrlf false
        & git config core.eol lf
        & git checkout -- . 2>$null
        & git clean -fd 2>$null
    } finally {
        Pop-Location
    }
    # Enforce pure LF endings on all Python source files in sandbox
    & $VenvPy -c "from pathlib import Path; [p.write_bytes(p.read_bytes().replace(b'\r\n', b'\n')) for p in Path(r'$RunDir').rglob('*.py') if p.is_file()]"

    # --- 3. Mode Configuration (A/B Setup) ---
    $PiExtraArgs = @()

    if ($Mode -eq "baseline") {
        Write-Host "  -> Configuring Mode A (Baseline)..." -ForegroundColor Yellow
        # Ensure .ki-base is completely absent in Baseline mode
        Remove-Item -Path (Join-Path $RunDir ".ki-base") -Recurse -Force -ErrorAction SilentlyContinue
        # Deploy realistic maintainer guidelines (no spoilers, no MCP)
        Copy-Item -Path (Join-Path $TasksDir "templates\AGENTS.baseline.md") -Destination (Join-Path $RunDir "AGENTS.md") -Force
        $PiExtraArgs += @("--no-mcp", "--tools", "read,bash,edit,write,grep,find,ls")
    }
    else {
        Write-Host "  -> Configuring Mode B (KI-Enabled with StreamableHTTP supergateway)..." -ForegroundColor Green
        # Copy curated knowledge base into sandbox without nesting .ki-base/.ki-base
        $kiDest = Join-Path $RunDir ".ki-base"
        Remove-Item -Path $kiDest -Recurse -Force -ErrorAction SilentlyContinue
        $kiSource = Join-Path $TargetRepo ".ki-base"
        Copy-Item -Path $kiSource -Destination $kiDest -Recurse -Force
        $PiExtraArgs += @("--tools", "read,bash,edit,write,grep,find,ls,mcp__*")

        # Deploy enriched guidelines with Knowledge Items & ADRs
        Copy-Item -Path (Join-Path $TasksDir "templates\AGENTS.ki.md") -Destination (Join-Path $RunDir "AGENTS.md") -Force

        # Update .ki-base/config.json with active sandbox path
        $kiCfgFile = Join-Path $RunDir ".ki-base\config.json"
        if (Test-Path $kiCfgFile) {
            $cfg = Get-Content $kiCfgFile -Raw | ConvertFrom-Json
            $cfg.venv_python = $VenvPy
            $cfg | ConvertTo-Json -Depth 5 | Set-Content $kiCfgFile -Encoding UTF8
        }

        # Ephemeral port allocation & supergateway startup
        $Port = Get-FreePort 3005
        Write-Host "  -> Starting supergateway on port $Port..." -ForegroundColor DarkCyan

        $sgOut = Join-Path $ArtifactsDir "supergateway_out.log"
        $sgErr = Join-Path $ArtifactsDir "supergateway_err.log"
        $Stdio = "$KiVenvPy -m ki_manager.server --workspace `"$RunDir`" --config `"$RunDir\.ki-base\ki_config.json`" --tool-mode compact"

        $sgProcess = Start-Process -FilePath "npx.cmd" -ArgumentList @(
            "supergateway", "--stdio", "`"$Stdio`"",
            "--outputTransport", "streamableHttp", "--stateful",
            "--port", "$Port", "--healthEndpoint", "/healthz"
        ) -RedirectStandardOutput $sgOut -RedirectStandardError $sgErr -WindowStyle Hidden -PassThru

        # Wait for supergateway /healthz readiness (up to 15s)
        $ready = $false
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.ElapsedMilliseconds -lt 15000) {
            Start-Sleep -Milliseconds 500
            try {
                $resp = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/healthz" -TimeoutSec 1 -ErrorAction Stop
                if ($resp -match "ok") { $ready = $true; break }
            } catch {}
        }
        if (-not $ready) {
            throw "supergateway failed to start and respond to /healthz on port $Port within 15 seconds."
        }
        Write-Host "  -> supergateway ready at http://127.0.0.1:$Port/mcp" -ForegroundColor Green

        # Write global MCP configuration with direct tool exposure
        $mcpConfig = @{
            mcpServers = @{
                "ki-manager" = @{
                    url = "http://127.0.0.1:$Port/mcp"
                    exposure = "direct"
                }
            }
        } | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText((Join-Path $AgentDir "mcp.json"), $mcpConfig, (New-Object System.Text.UTF8Encoding $false))
    }

    # --- 4. Read Prompt ---
    $PromptFile = Join-Path $TasksDir "prompts\$Task.txt"
    if (-not (Test-Path $PromptFile)) {
        throw "Prompt file not found: $PromptFile"
    }
    $AgentPromptFile = Join-Path $AgentDir "PROMPT.txt"
    Copy-Item -Path $PromptFile -Destination $AgentPromptFile -Force

    if ($DryRun) {
        Write-Host "`n[DRY RUN] Simulation complete. No Docker container or API calls executed." -ForegroundColor Magenta
        return
    }

    # --- 5. Container Execution ---
    Write-Host "  -> Spawning sandboxed agent in Docker (pi-secure)..." -ForegroundColor Cyan
    $ContainerLog = Join-Path $ArtifactsDir "container.log"

    $piFlags = @(
        "--provider", "openrouter",
        "--model", $Model,
        "--mode", "json",
        "--session-dir", "/pi-agent/sessions",
        "--no-skills",
        "--no-prompt-templates",
        "--no-themes"
    )
    if ($Thinking) {
        $piFlags += @("--thinking", $Thinking)
    } elseif ($Model -match "gemini") {
        # OpenRouter's Gemini proxy fails on multi-turn replay of encrypted reasoning tokens
        $piFlags += @("--thinking", "off")
    }
    $piFlags += $PiExtraArgs

    $LaunchSh = Join-Path $AgentDir "launch_pi.sh"
    $shContent = "#!/bin/bash`nexec pi -p `"`$(cat /pi-agent/PROMPT.txt)`" " + ($piFlags -join " ") + "`n"
    [System.IO.File]::WriteAllText($LaunchSh, $shContent, (New-Object System.Text.UTF8Encoding $false))

    $dockerArgs = @(
        "run", "--rm",
        "--name", $ContainerName,
        "--network", "host",
        "--cap-drop", "ALL",
        "--security-opt", "no-new-privileges",
        "-e", "OPENROUTER_API_KEY=$($env:OPENROUTER_API_KEY)",
        "-e", "PI_CODING_AGENT_DIR=/pi-agent",
        "-e", "PI_OFFLINE=1",
        "-v", "${RunDir}:/app:rw",
        "-v", "${AgentDir}:/pi-agent:rw",
        "-v", "${EmptyExtFile}:/pi-extensions.txt:ro",
        "--workdir", "/app",
        "pi-secure:latest",
        "bash", "/pi-agent/launch_pi.sh"
    )

    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", "`"$DockerScript`"", ($dockerArgs -join " ")
    ) -RedirectStandardOutput $ContainerLog -RedirectStandardError (Join-Path $ArtifactsDir "container_err.log") -WindowStyle Hidden -PassThru

    # Monitor with timeout watcher
    $timeoutSw = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $proc.HasExited) {
        Start-Sleep -Seconds 2
        if ($timeoutSw.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
            $timedOut = $true
            Write-Host "  WARNING: Execution timeout ($TimeoutSeconds s) exceeded! Forcibly terminating..." -ForegroundColor Red
            & $DockerScript rm -f $ContainerName 2>$null
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            break
        }
    }

    try { $proc.WaitForExit() } catch {}
    $containerExitCode = if ($timedOut) { -999 } else { if ($proc.ExitCode -ne $null) { [int]$proc.ExitCode } else { 0 } }
    Write-Host "  -> Agent execution finished (Exit Code: $containerExitCode, Elapsed: $([int]$timeoutSw.Elapsed.TotalSeconds)s)" -ForegroundColor Gray

    # --- 6. Persist Session Telemetry ---
    $sessionFiles = Get-ChildItem -Path (Join-Path $AgentDir "sessions") -Filter "*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($sessionFiles -and $sessionFiles.Count -gt 0) {
        Copy-Item -Path $sessionFiles[0].FullName -Destination (Join-Path $ArtifactsDir "pi_session.jsonl") -Force
        Write-Host "  -> Session JSONL persisted: $($sessionFiles[0].Name)" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: No session JSONL was generated by Pi." -ForegroundColor Yellow
        [System.IO.File]::WriteAllText((Join-Path $ArtifactsDir "pi_session.jsonl"), "")
    }

    # --- 7. Extract Git Diff ---
    Write-Host "  -> Extracting patch.diff..." -ForegroundColor Gray
    Push-Location $RunDir
    try {
        # Restore AGENTS.md and .ki-base so setup differences do not pollute agent code diff
        Remove-Item -Path (Join-Path $RunDir ".ki-base") -Recurse -Force -ErrorAction SilentlyContinue
        & git checkout -- AGENTS.md .ki-base 2>$null
        # Include any newly created files (e.g. rich/badge.py)
        & git add -N . 2>$null
        $diff = & git diff HEAD -- . ":!AGENTS.md" ":!.ki-base"
        [System.IO.File]::WriteAllText((Join-Path $ArtifactsDir "patch.diff"), ($diff -join "`n"), (New-Object System.Text.UTF8Encoding $false))
    } finally {
        Pop-Location
    }

    # --- 8. Post-Run Anti-Cheating Grading (ADR-0001) ---
    Write-Host "  -> Running isolated post-run evaluation tests..." -ForegroundColor Cyan
    $EvalTestSrc = Join-Path $TasksDir "eval_tests\test_${Task}_eval.py"
    $EvalTestDst = Join-Path $RunDir "tests\test_${Task}_eval.py"

    if (Test-Path $EvalTestSrc) {
        Copy-Item -Path $EvalTestSrc -Destination $EvalTestDst -Force
        $gradeJson = Join-Path $ArtifactsDir "grade.json"
        
        $env:PYTHONPATH = $RunDir
        & $VenvPy -m pytest $EvalTestDst --json-report --json-report-file=$gradeJson -q 2>&1 | Out-Null
        
        # Clean up hidden test immediately following evaluation
        Remove-Item -Path $EvalTestDst -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $RunDir "tests\__pycache__") -Recurse -Force -ErrorAction SilentlyContinue

        if (Test-Path $gradeJson) {
            $report = Get-Content $gradeJson -Raw | ConvertFrom-Json
            $passed = $report.summary.passed
            $failed = $report.summary.failed
            Write-Host "  [EVAL GRADE] Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0 -and $passed -gt 0) { "Green" } else { "Red" })
        }
    }

    # --- 9. Run Regression Test Suite ---
    Write-Host "  -> Running regression test suite..." -ForegroundColor Gray
    $regressionTests = switch ($Task) {
        "task1" { @("tests/test_ratio.py", "tests/test_table.py") }
        "task2" { @("tests/test_style.py", "tests/test_markup.py") }
        "task3" { @("tests/test_protocol.py", "tests/test_panel.py", "tests/test_table.py") }
    }
    
    $regTargets = $regressionTests | ForEach-Object { Join-Path $RunDir $_ }
    $regGradeJson = Join-Path $ArtifactsDir "regression_grade.json"
    $env:PYTHONPATH = $RunDir
    & $VenvPy -m pytest @regTargets --json-report --json-report-file=$regGradeJson -q 2>&1 | Out-Null

} finally {
    # --- 10. Guaranteed Teardown (ADR-0003) ---
    Write-Host "  -> Executing deterministic cleanup..." -ForegroundColor Gray

    if ($sgProcess -and -not $sgProcess.HasExited) {
        & taskkill.exe /PID $sgProcess.Id /T /F 2>$null | Out-Null
        Stop-Process -Id $sgProcess.Id -Force -ErrorAction SilentlyContinue
    }
    & $DockerScript rm -f $ContainerName 2>$null | Out-Null

    $endTime = Get-Date
    $duration = [int]($endTime - $startTime).TotalSeconds

    # Persist run metadata
    $runMeta = @{
        run_id = $RunId
        task = $Task
        mode = $Mode
        model = $Model
        attempt = $Attempt
        start_time = $startTime.ToString("o")
        end_time = $endTime.ToString("o")
        duration_seconds = $duration
        timed_out = $timedOut
        exit_code = $containerExitCode
    } | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText((Join-Path $ArtifactsDir "run_meta.json"), $runMeta, (New-Object System.Text.UTF8Encoding $false))

    if (-not $KeepTemp) {
        & $VenvPy -c "import shutil; shutil.rmtree(r'$RunDir', ignore_errors=True); shutil.rmtree(r'$AgentDir', ignore_errors=True)"
    }

    Write-Host " [RUNNER] Run $RunId completed in ${duration}s.`n" -ForegroundColor Cyan
}

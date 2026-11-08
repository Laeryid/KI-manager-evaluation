"""
analysis/evaluate_results.py

Telemetry ingestion, statistical analysis, and report generation
for the KI-Manager Evaluation Benchmark.

Parses Pi 1.5.0 JSONL sessions, pytest grade reports, and patch diffs.
Calculates Pass Rates, Time-to-First-Edit, Token Usage, and OpenRouter Billing.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional


@dataclass
class RunRecord:
    run_id: str
    task: str
    mode: str
    model: str
    attempt: int
    duration_seconds: int
    timed_out: bool
    exit_code: int
    eval_passed: bool
    eval_failed_count: int
    eval_passed_count: int
    regression_passed: bool
    solved: bool
    total_turns: int
    first_edit_turn: int
    ki_tool_calls: int
    exploration_calls: int
    bash_calls: int
    input_tokens: int
    output_tokens: int
    cache_read_tokens: int
    cache_write_tokens: int
    total_tokens: int
    cost_usd: float
    diff_lines_added: int
    diff_lines_removed: int
    files_modified: int


def parse_diff(patch_file: Path) -> tuple[int, int, int]:
    """Parse unified git diff to compute lines added, removed, and files touched."""
    if not patch_file.exists():
        return 0, 0, 0
    added, removed = 0, 0
    files = set()
    try:
        content = patch_file.read_text(encoding="utf-8", errors="replace")
        for line in content.splitlines():
            if line.startswith("+++ b/"):
                files.add(line[6:])
            elif line.startswith("+") and not line.startswith("+++"):
                added += 1
            elif line.startswith("-") and not line.startswith("---"):
                removed += 1
    except Exception:
        pass
    return added, removed, len(files)


def parse_pi_session(session_file: Path) -> dict[str, Any]:
    """
    Parse Pi 1.5.0 JSONL session.
    Extracts assistant turns, token usage, cost, and tool invocation sequences.
    """
    total_turns = 0
    first_edit_turn: Optional[int] = None
    ki_tool_calls = 0
    exploration_calls = 0
    bash_calls = 0
    input_tokens = 0
    output_tokens = 0
    cache_read_tokens = 0
    cache_write_tokens = 0
    total_tokens = 0
    cost_usd = 0.0

    if not session_file.exists() or session_file.stat().st_size == 0:
        return {
            "total_turns": 0,
            "first_edit_turn": 0,
            "ki_tool_calls": 0,
            "exploration_calls": 0,
            "bash_calls": 0,
            "input_tokens": 0,
            "output_tokens": 0,
            "cache_read_tokens": 0,
            "cache_write_tokens": 0,
            "total_tokens": 0,
            "cost_usd": 0.0,
        }

    try:
        with open(session_file, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except Exception:
                    continue

                if event.get("type") != "message":
                    continue

                msg = event.get("message", {})
                role = msg.get("role")

                if role == "assistant":
                    total_turns += 1

                    # Usage and billing extraction
                    usage = msg.get("usage", {})
                    if usage:
                        input_tokens += usage.get("input", 0)
                        output_tokens += usage.get("output", 0)
                        cache_read_tokens += usage.get("cacheRead", 0)
                        cache_write_tokens += usage.get("cacheWrite", 0)
                        total_tokens += usage.get("totalTokens", 0)
                        cost_data = usage.get("cost", {})
                        if isinstance(cost_data, dict):
                            cost_usd += cost_data.get("total", 0.0)

                    # Tool call extraction
                    contents = msg.get("content", [])
                    if isinstance(contents, list):
                        for item in contents:
                            if not isinstance(item, dict):
                                continue
                            if item.get("type") == "toolCall":
                                tool_name = item.get("name", "")

                                # First edit tracking
                                if first_edit_turn is None and tool_name in ("edit", "write"):
                                    first_edit_turn = total_turns

                                # MCP ki-manager calls
                                if tool_name.startswith("mcp__ki_manager__") or tool_name.startswith("ki_"):
                                    ki_tool_calls += 1

                                # Standard inspection & discovery
                                if tool_name in ("read", "grep", "find", "ls"):
                                    exploration_calls += 1

                                if tool_name == "bash":
                                    bash_calls += 1
    except Exception as exc:
        print(f"Warning: Error parsing session {session_file}: {exc}", file=sys.stderr)

    return {
        "total_turns": total_turns,
        "first_edit_turn": first_edit_turn if first_edit_turn is not None else total_turns,
        "ki_tool_calls": ki_tool_calls,
        "exploration_calls": exploration_calls,
        "bash_calls": bash_calls,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cache_read_tokens": cache_read_tokens,
        "cache_write_tokens": cache_write_tokens,
        "total_tokens": total_tokens or (input_tokens + output_tokens + cache_read_tokens),
        "cost_usd": round(cost_usd, 6),
    }


def parse_pytest_report(report_file: Path) -> tuple[bool, int, int]:
    """Parse pytest-json-report to extract pass status and counts."""
    if not report_file.exists():
        return False, 1, 0
    try:
        data = json.loads(report_file.read_text(encoding="utf-8"))
        summary = data.get("summary", {})
        passed = summary.get("passed", 0)
        failed = summary.get("failed", 0) + summary.get("error", 0)
        is_success = (failed == 0 and passed > 0)
        return is_success, failed, passed
    except Exception:
        return False, 1, 0


def parse_run_dir(run_path: Path) -> Optional[RunRecord]:
    """Ingest a complete benchmark run folder."""
    meta_file = run_path / "run_meta.json"
    if not meta_file.exists():
        # Fallback metadata from directory name: {task}_{mode}_{model}_att{attempt}
        parts = run_path.name.split("_")
        if len(parts) < 4:
            return None
        task = parts[0]
        mode = parts[1]
        attempt = 1
        model = "unknown"
        meta = {
            "run_id": run_path.name,
            "task": task,
            "mode": mode,
            "model": model,
            "attempt": attempt,
            "duration_seconds": 0,
            "timed_out": False,
            "exit_code": 0,
        }
    else:
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
        except Exception:
            return None

    run_id = meta.get("run_id", run_path.name)
    task = meta.get("task", "task1")
    mode = meta.get("mode", "baseline")
    model = meta.get("model", "unknown")
    attempt = int(meta.get("attempt", 1))
    duration = int(meta.get("duration_seconds", 0))
    timed_out = bool(meta.get("timed_out", False))
    exit_code = int(meta.get("exit_code", 0))

    # Pytest evaluation grades
    eval_passed, eval_failed_cnt, eval_passed_cnt = parse_pytest_report(run_path / "grade.json")
    regression_passed, _, _ = parse_pytest_report(run_path / "regression_grade.json")

    # Overall solution validity
    solved = eval_passed and regression_passed and not timed_out

    # Pi telemetry
    session_metrics = parse_pi_session(run_path / "pi_session.jsonl")

    # Git patch
    diff_added, diff_removed, files_mod = parse_diff(run_path / "patch.diff")

    return RunRecord(
        run_id=run_id,
        task=task,
        mode=mode,
        model=model,
        attempt=attempt,
        duration_seconds=duration,
        timed_out=timed_out,
        exit_code=exit_code,
        eval_passed=eval_passed,
        eval_failed_count=eval_failed_cnt,
        eval_passed_count=eval_passed_cnt,
        regression_passed=regression_passed,
        solved=solved,
        total_turns=session_metrics["total_turns"],
        first_edit_turn=session_metrics["first_edit_turn"],
        ki_tool_calls=session_metrics["ki_tool_calls"],
        exploration_calls=session_metrics["exploration_calls"],
        bash_calls=session_metrics["bash_calls"],
        input_tokens=session_metrics["input_tokens"],
        output_tokens=session_metrics["output_tokens"],
        cache_read_tokens=session_metrics["cache_read_tokens"],
        cache_write_tokens=session_metrics["cache_write_tokens"],
        total_tokens=session_metrics["total_tokens"],
        cost_usd=session_metrics["cost_usd"],
        diff_lines_added=diff_added,
        diff_lines_removed=diff_removed,
        files_modified=files_mod,
    )


def compute_cumulative_cost(input_dir: Path) -> float:
    """Calculate cumulative spend across all runs."""
    total = 0.0
    for session_file in input_dir.rglob("pi_session.jsonl"):
        metrics = parse_pi_session(session_file)
        total += metrics["cost_usd"]
    return round(total, 4)


def aggregate_metrics(records: List[RunRecord]) -> List[Dict[str, Any]]:
    """Group and aggregate metrics by (model, mode)."""
    groups: Dict[tuple[str, str], List[RunRecord]] = {}
    for r in records:
        key = (r.model, r.mode)
        groups.setdefault(key, []).append(r)

    rows = []
    for (model, mode), recs in sorted(groups.items()):
        total_runs = len(recs)
        solved_runs = sum(1 for r in recs if r.solved)
        pass_rate = round(solved_runs / total_runs * 100.0, 1) if total_runs else 0.0
        avg_turns = round(sum(r.total_turns for r in recs) / total_runs, 1) if total_runs else 0.0
        avg_first_edit = round(sum(r.first_edit_turn for r in recs) / total_runs, 1) if total_runs else 0.0
        avg_cost = round(sum(r.cost_usd for r in recs) / total_runs, 4) if total_runs else 0.0
        total_cost = sum(r.cost_usd for r in recs)
        cost_per_solved = round(total_cost / solved_runs, 4) if solved_runs else 0.0
        avg_ki_calls = round(sum(r.ki_tool_calls for r in recs) / total_runs, 1) if total_runs else 0.0
        avg_exploration = round(sum(r.exploration_calls for r in recs) / total_runs, 1) if total_runs else 0.0

        # Pass rate per task
        t1_runs = [r for r in recs if r.task == "task1"]
        t2_runs = [r for r in recs if r.task == "task2"]
        t3_runs = [r for r in recs if r.task == "task3"]

        pr_t1 = round(sum(1 for r in t1_runs if r.solved) / len(t1_runs) * 100.0, 1) if t1_runs else 0.0
        pr_t2 = round(sum(1 for r in t2_runs if r.solved) / len(t2_runs) * 100.0, 1) if t2_runs else 0.0
        pr_t3 = round(sum(1 for r in t3_runs if r.solved) / len(t3_runs) * 100.0, 1) if t3_runs else 0.0

        rows.append({
            "model": model,
            "mode": mode,
            "total_runs": total_runs,
            "solved_runs": solved_runs,
            "pass_rate_pct": pass_rate,
            "pass_rate_task1": pr_t1,
            "pass_rate_task2": pr_t2,
            "pass_rate_task3": pr_t3,
            "avg_turns": avg_turns,
            "avg_first_edit_turn": avg_first_edit,
            "avg_cost_usd": avg_cost,
            "cost_per_solved_usd": cost_per_solved,
            "avg_ki_calls": avg_ki_calls,
            "avg_exploration_calls": avg_exploration,
        })
    return rows


def generate_markdown_report(summary_rows: List[Dict[str, Any]], total_cost: float, output_file: Path) -> None:
    """Generate professional Markdown evaluation report."""
    md = []
    md.append("# KI-Manager Evaluation Benchmark — Consolidated Report\n")
    md.append(f"> **Total Evaluated Cost:** `${total_cost:.4f} USD`  ")
    md.append(f"> **Generated:** `2026-11-08`\n")
    md.append("## 1. Summary Performance Matrix\n")
    md.append("| Model | Mode | Overall Pass % | Task 1 (Bugfix) | Task 2 (Feature) | Task 3 (ADR) | Avg Turns | 1st Edit Turn | Avg Cost / Run | Cost / Solved | KI Calls | Exploration Calls |")
    md.append("| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |")

    for row in summary_rows:
        mode_badge = f"**{row['mode']}**" if row["mode"] == "ki" else row["mode"]
        pr_str = f"**{row['pass_rate_pct']}%**" if row["mode"] == "ki" else f"{row['pass_rate_pct']}%"
        md.append(
            f"| `{row['model']}` | {mode_badge} | {pr_str} | {row['pass_rate_task1']}% | "
            f"{row['pass_rate_task2']}% | {row['pass_rate_task3']}% | {row['avg_turns']} | "
            f"{row['avg_first_edit_turn']} | `${row['avg_cost_usd']:.4f}` | "
            f"`${row['cost_per_solved_usd']:.4f}` | {row['avg_ki_calls']} | {row['avg_exploration_calls']} |"
        )

    md.append("\n## 2. Key Hypotheses Verification\n")
    md.append("1. **Time-to-First-Edit Efficiency:** Comparing turns taken before first code modification in Baseline vs KI-mode.")
    md.append("2. **Exploration Waste Reduction:** Quantifying reduction in blind `grep`/`find`/`read` calls through indexed BM25 search (`ki_search`).")
    md.append("3. **ADR Compliance Rate:** Verifying zero architectural violations on Task 3 (`rich/badge.py`).\n")

    output_file.write_text("\n".join(md), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate KI-Manager Benchmark Results.")
    parser.add_argument("--input-dir", "-i", type=str, default="results", help="Directory containing run results.")
    parser.add_argument("--output-dir", "-o", type=str, default="results/summary", help="Directory for summary outputs.")
    parser.add_argument("--check-budget", action="store_true", help="Print total expenditure and verify circuit breaker.")
    parser.add_argument("--budget-limit", type=float, default=80.0, help="Budget threshold in USD.")
    args = parser.parse_args()

    input_path = Path(args.input_dir).resolve()

    if args.check_budget:
        total = compute_cumulative_cost(input_path)
        print(f"Cumulative spend: ${total:.4f} USD (Threshold: ${args.budget_limit:.2f} USD)")
        if total >= args.budget_limit:
            print("ALERT: Financial circuit breaker limit exceeded!", file=sys.stderr)
            sys.exit(80)
        sys.exit(0)

    output_path = Path(args.output_dir).resolve()
    output_path.mkdir(parents=True, exist_ok=True)

    records: List[RunRecord] = []
    for item in sorted(input_path.iterdir()):
        if item.is_dir() and item.name != "summary":
            rec = parse_run_dir(item)
            if rec:
                records.append(rec)

    print(f"Parsed {len(records)} benchmark run directories.")

    # Export granular CSV
    runs_csv = output_path / "benchmark_runs.csv"
    if records:
        fieldnames = list(asdict(records[0]).keys())
        with open(runs_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            for r in records:
                writer.writerow(asdict(r))
        print(f"Saved run records to {runs_csv}")

    # Export aggregated summary CSV & Markdown
    summary_rows = aggregate_metrics(records)
    summary_csv = output_path / "benchmark_summary.csv"
    if summary_rows:
        sum_fields = list(summary_rows[0].keys())
        with open(summary_csv, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=sum_fields)
            writer.writeheader()
            for row in summary_rows:
                writer.writerow(row)
        print(f"Saved aggregated summary to {summary_csv}")

    total_cost = sum(r.cost_usd for r in records)
    report_md = output_path / "benchmark_report.md"
    generate_markdown_report(summary_rows, total_cost, report_md)
    print(f"Saved report to {report_md}")


if __name__ == "__main__":
    main()

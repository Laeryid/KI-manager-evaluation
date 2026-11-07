# Фаза 6: Парсинг метрик, аналитическая обработка и финальный отчёт

> **Цель фазы:** Автоматически агрегировать результаты 162 прогонов, рассчитать ключевые статистические метрики (Pass Rate, Cost, Time-to-First-Edit, ADR Compliance), проверить исследовательские гипотезы и сформировать наглядный публичный отчёт.

---

## 1. Задачи фазы

1. **Разработка скрипта агрегации (`evaluate_results.py`)**:
   - Парсинг файлов `grade.json` (статус прохождения тестов).
   - Парсинг `pi_session.jsonl` (детализация каждого шага, вызовы тулов, токены, Prompt Cache, биллинг OpenRouter).
   - Парсинг `patch.diff` (размер изменений, затронутые файлы).
2. **Расчёт ключевых сравнительных метрик**:
   - **Pass Rate (%):** Доля успешных прогонов для каждой модели в режиме Baseline vs KI-Enabled.
   - **Cost-per-Solved-Task ($):** Сколько стоит одно успешное решение задачи в каждом режиме.
   - **Time-to-First-Edit (Шаги / Секунды):** Сколько действий тратится на слепой поиск vs направленную навигацию.
   - **Navigation Waste (Холостые вызовы):** Число вызовов `grep`/`find`/`read` в Baseline против вызовов `ki_search`/`ki_read` в KI.
   - **ADR Compliance Rate:** Процент соблюдения архитектурного инварианта в Задаче 3.
3. **Проверка ключевых исследовательских гипотез**:
   - *Гипотеза 1:* Даёт ли связка «Tier 2 (например, Gemini 3.8 Flash / DeepSeek) + `ki-manager`» результат, сравнимый с Tier 1 (GPT-5.6 Sol / Claude Sonnet 4) без документации, но при стоимости в 5–8 раз ниже?
   - *Гипотеза 2:* Снижает ли `ki-manager` `Time-to-First-Edit` более чем в 2 раза?
   - *Гипотеза 3:* Помогает ли `ki-manager` исключить архитектурные нарушения (ADR) в сложных задачах?
4. **Генерация артефактов отчёта**:
   - Экспорт сырых данных в `benchmark_summary.csv`.
   - Формирование итогового отчёта `benchmark_final_report.md` со сводными таблицами и выводами.

---

## 2. Структура сводной таблицы метрик

Скрипт формирует сводные данные по каждой модели и режиму:

| Модель | Режим | Pass Rate (Task 1) | Pass Rate (Task 2) | Pass Rate (Task 3 ADR) | Avg. Turns | Avg. Cost / Run | Cost / Solved Task | Time to 1st Edit |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **GPT-5.6 Sol** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **GPT-5.6 Sol** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Claude Sonnet 4** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Claude Sonnet 4** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Gemini 4 Argon** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Gemini 4 Argon** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Gemini 3.8 Flash** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Gemini 3.8 Flash** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **DeepSeek v4.1** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **DeepSeek v4.1** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Qwen 2.5 Coder** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Qwen 2.5 Coder** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **GPT-5.6 Luna** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **GPT-5.6 Luna** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Claude Haiku 5.5** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Claude Haiku 5.5** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |
| **Gemini 2.5 Flash** | Baseline | % | % | % | ... | $... | $... | ... шагов |
| **Gemini 2.5 Flash** | **KI-Enabled** | **%** | **%** | **%** | **...** | **$...** | **$...** | **... шагов** |

---

## 3. Скрипт парсера телеметрии (`evaluate_results.py`)

Скрипт читает каждый прогон из `C:\AI\PI\benchmark_results\*`:
```python
import json
from pathlib import Path

def parse_run(run_dir: Path):
    grade_file = run_dir / "pytest_report.json"
    session_file = run_dir / "pi_session.jsonl"
    
    # 1. Оценка успешности
    grade_data = json.loads(grade_file.read_text()) if grade_file.exists() else {}
    passed = grade_data.get("summary", {}).get("failed", 1) == 0 and grade_data.get("summary", {}).get("passed", 0) > 0

    # 2. Парсинг телеметрии Pi
    turns, first_edit_turn, total_cost = 0, None, 0.0
    input_tokens, cached_tokens, output_tokens = 0, 0, 0
    ki_tool_calls = 0

    if session_file.exists():
        for line in session_file.read_text().splitlines():
            if not line.strip(): continue
            step = json.loads(line)
            turns += 1
            
            # Поиск первого редактирования
            tools_called = [c.get("name") for c in step.get("tool_calls", [])]
            if not first_edit_turn and any(t in ("edit", "write") for t in tools_called):
                first_edit_turn = turns
                
            if any(t.startswith("ki_") for t in tools_called):
                ki_tool_calls += 1
                
            # Учёт токенов и биллинга OpenRouter
            usage = step.get("usage", {})
            input_tokens += usage.get("input_tokens", 0)
            cached_tokens += usage.get("cached_tokens", 0)
            output_tokens += usage.get("output_tokens", 0)
            total_cost += step.get("cost", 0.0)

    return {
        "passed": passed,
        "turns": turns,
        "first_edit_turn": first_edit_turn or turns,
        "ki_tool_calls": ki_tool_calls,
        "total_cost": total_cost,
        "input_tokens": input_tokens,
        "cached_tokens": cached_tokens,
        "output_tokens": output_tokens
    }
```

---

## 4. Чек-лист готовности Фазы 6
- [ ] Написан и протестирован парсер `evaluate_results.py`.
- [ ] Сформирован файл `benchmark_summary.csv` со всеми 162 строками результатов.
- [ ] Построены агрегированные таблицы (по моделям, по задачам, по классам).
- [ ] Сгенерирован финальный отчёт `benchmark_final_report.md` с выводами по гипотезам.
- [ ] Подготовлены тезисы для публикации в блоге / социальных сетях / репозитории проекта.

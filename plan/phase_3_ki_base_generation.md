# Фаза 3: Разметка базы знаний `.ki-base` и верификация качества

> **Цель фазы:** Построить полноценную, архитектурно точную базу знаний `.ki-base/` над репозиторием `Textualize/rich`, создать ключевые ADR и сгенерировать компактный навигационный файл `AGENTS.md`.

---

## 1. Задачи фазы

1. **Анализ кодовой базы средствами `ki-manager`**:
   - Запуск `ki_init_project` в чистом эталоне `rich`.
   - Прогон `audit_coverage` и построение графа зависимостей через `analyze_all_dependencies`.
   - Формирование списка ключевых модулей, требующих документирования (15–20 ключевых узлов).
2. **Генерация Knowledge Items (KI)**:
   - Создание структуры скаффолдов через `ki_scaffold`.
   - Заполнение KI-файлов сильной моделью (`google/gemini-4-argon` или `anthropic/claude-sonnet-4`) с описанием инвариантов, потоков данных и скрытых ловушек.
3. **Фиксация архитектурных решений (ADR)**:
   - **ADR-0001**: Концепция разбивки на терминальные сегменты (`Segment`) и протокол `ConsoleRenderable`.
   - **ADR-0002**: Правила сложения и наследования стилей (`Style`) и работа с ANSI-последовательностями.
   - **ADR-0003**: Алгоритмы распределения пространства (`_ratio.py`, `Layout`, `Table`).
4. **Синхронизация навигации для AI-агентов**:
   - Автоматическая генерация `AGENTS.md` через `sync_agents_md`.
   - Включение описания компактного режима `ki-manager` (`ki_list`, `ki_search`, `ki_read`).
5. **Тестирование поискового движка (Search Validation)**:
   - Проверка выдачи BM25-поиска (`ki_search`) по ключевым запросам из 3 задач.

---

## 2. Карта Knowledge Items (Целевой охват)

```
.ki-base/
├── config.json                     # Конфигурация базы знаний
├── dir-index.json                  # Индекс директорий и модулей
├── index.json                      # Каталог Knowledge Items
├── adr/
│   ├── 0001-terminal-segments.md
│   ├── 0002-render-protocol.md
│   └── 0003-ratio-and-layout.md
└── knowledge/
    ├── core/
    │   ├── ki-console.md           # Главный фасад Console, буфер, печать
    │   ├── ki-segment.md           # Атомарный кирпичик рендеринга Segment
    │   ├── ki-measure.md           # Измерение минимальной/максимальной ширины
    │   └── ki-protocol.md          # Протоколы __rich_console__ и __rich_measure__
    ├── styling/
    │   ├── ki-style.md             # Класс Style, атрибуты, сложение, кэширование
    │   ├── ki-color.md             # Цветовые пространства: standard, 256, truecolor
    │   └── ki-palette.md           # Системные палитры и ANSI-экранирование
    ├── layout/
    │   ├── ki-table.md             # Таблицы, колонки, паддинги, сжатие
    │   ├── ki-ratio.md             # Алгоритм распределения пропорций (_ratio.py)
    │   ├── ki-layout.md            # Древовидная сетка разбивки экрана
    │   └── ki-panel.md             # Панели, рамки, выравнивание
    └── text/
        ├── ki-text.md              # Класс Text, спаны, форматирование
        └── ki-markup.md            # Парсер тэгов [bold red]...[/]
```

---

## 3. Процесс генерации и верификации

### Шаг 3.1: Первичная инициализация
```powershell
$RichPath = "C:\Experiments\benchmark_rich"
$VenvPy = "C:\Experiments\KI-base\.venv\Scripts\python.exe"

& $VenvPy -c "
from ki_manager.tools.scaffold import ki_init_project
print(ki_init_project('$RichPath'))
"
```

### Шаг 3.2: Анализ зависимостей и аудит
```powershell
& $VenvPy -m ki_manager.scripts.audit_coverage --workspace "$RichPath"
& $VenvPy -m ki_manager.scripts.generate_dir_index --workspace "$RichPath"
```

### Шаг 3.3: Заполнение KI и ADR
Используем скрипт с прямым обращением к API Gemini 4 Argon / Claude Sonnet для наполнения каждого KI:
- Описание назначения файла.
- Публичный API и входные/выходные типы.
- Скрытые инварианты (например: «`_ratio.ratio_resolve` ожидает список целых чисел и падает при нулевом общем весе»).
- Зависимости («Кто вызывает» и «Кого вызывает»).

### Шаг 3.4: Синхронизация `AGENTS.md`
```powershell
& $VenvPy -c "
from ki_manager.scripts.sync_agents import sync_agents_md
sync_agents_md('$RichPath')
"
```

### Шаг 3.5: Тестирование BM25-поиска
Проверяем, что агент в режиме KI легко находит нужные документы по запросам из задач:
```python
# Тестовый запрос для Задачи 1
results = ki_search({"query": "ratio resolve table column width", "page": 1})
assert any("ki-ratio" in r["title"] or "ki-table" in r["title"] for r in results["items"])

# Тестовый запрос для Задачи 3
results = ki_search({"query": "render protocol rich_console custom component", "page": 1})
assert any("0002-render-protocol" in r["title"] or "ki-protocol" in r["title"] for r in results["items"])
```

---

## 4. Чек-лист готовности Фазы 3
- [ ] Папка `.ki-base/` создана и содержит $\ge 15$ валидных KI и 3 ключевых ADR.
- [ ] Файл `AGENTS.md` сгенерирован и содержит компактные инструкции для AI-агентов.
- [ ] Все вызовы `ki_search`, `ki_read`, `ki_list` корректно отрабатывают через `ki_manager.server`.
- [ ] Создан эталонный архив/снапшот `rich_with_ki.zip` для мгновенного развёртывания в прогонах Режима B.

# Фаза 1: Апгрейд тестового стенда Pi и окружения Docker

> **Цель фазы:** Подготовить полностью детерминированный, безопасный и автоматизированный харнесс на базе `C:\AI\PI` с поддержкой актуальной версии Pi 1.0+, нативного MCP через `supergateway` и прямого переключения между Baseline и KI режимами.

---

## 1. Задачи фазы

1. **Обновление Docker-образа `pi-secure`**:
   - Переход на актуальный глобальный релиз `@mariozechner/pi-coding-agent` (версия 1.0+).
   - Удаление устаревшего плагина `pi-mcp-adapter` из `docker/pi-extensions.txt`.
   - Проверка наличия в контейнере необходимых утилит: `python3`, `git`, `curl`, `ripgrep`, `fd`.
2. **Настройка нативного MCP over SSE**:
   - Отказ от нестабильных обёрток в пользу нативного ядра Pi 1.0 (`builtin:mcp`).
   - Подключение `ki-manager` через `supergateway` по адресу `http://host.docker.internal:<PORT>/sse`.
3. **Поддержка переключателя режимов (Baseline vs KI)**:
   - Внедрение флага `--no-mcp` для 100% изоляции Baseline-прогонов.
   - Изоляция глобальных настроек: отключение `codegraph` и лишних плагинов во время тестов.
4. **Конфигурация OpenRouter**:
   - Передача переменной `OPENROUTER_API_KEY` в контейнер без утечки в артефакты репозитория.

---

## 2. Пошаговые изменения в `C:\AI\PI`

### 2.1. Ревизия `C:\AI\PI\docker\pi-extensions.txt`
В Pi 1.0+ функциональность MCP встроена в ядро. Удаляем адаптер:
```diff
- npm:pi-mcp-adapter
  npm:@plannotator/pi-extension
```

### 2.2. Проверка `C:\AI\PI\docker\Dockerfile`
Убедиться, что образ ставит последнюю версию Pi и сохраняет минимальные привилегии:
```dockerfile
FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y \
    git curl dos2unix \
    python3 python3-venv python3-pip \
    make g++ \
    fd-find ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s $(which fdfind) /usr/local/bin/fd
RUN npm install -g @mariozechner/pi-coding-agent@latest

COPY pi-extensions.txt /pi-extensions.txt
COPY entrypoint.sh /entrypoint.sh

RUN userdel -r node && useradd -m -u 1000 -s /bin/bash agent
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 19432
USER agent
WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]
```

### 2.3. Пересборка контейнера
Запуск на хосте:
```powershell
Set-Location C:\AI\PI
.\update_pi.ps1 -NoCache
```

---

## 3. Архитектура подключения `supergateway` к `ki-manager`

В бенчмарке каждый прогон с `ki-manager` поднимает легковесный выделенный процесс `supergateway` на свободном порту (например, 3005):

```powershell
# Запуск MCP сервера на хосте Windows
$VenvPy = "C:\Experiments\KI-base\.venv\Scripts\python.exe"
$WorkspaceHostPath = "C:\AI\PI\temp_runs\run_001"
$McpPort = 3005

$StdioCommand = "$VenvPy -m ki_manager.server --workspace `"$WorkspaceHostPath`" --tool-mode compact"
$proc = Start-Process -FilePath "npx.cmd" `
    -ArgumentList "supergateway", "--stdio", "`"$StdioCommand`"", "--port", "$McpPort" `
    -WindowStyle Hidden -PassThru
```

В рабочей папке задачи создается конфигурационный файл `.pi/mcp.json`:
```json
{
  "mcpServers": {
    "ki-manager": {
      "url": "http://host.docker.internal:3005/sse"
    }
  }
}
```

---

## 4. Схема запуска контейнера в неинтерактивном (batch) режиме

Каждый прогон инициируется автономной командой `docker run`:

```powershell
docker run --rm `
  --name "bench-$runId" `
  --add-host "host.docker.internal:host-gateway" `
  -v "${RunDirHost}:/app:rw" `
  -e "OPENROUTER_API_KEY=$env:OPENROUTER_API_KEY" `
  --cap-drop "ALL" `
  --security-opt "no-new-privileges" `
  --workdir "/app" `
  pi-secure `
  -p "$TaskPrompt" `
  --provider openrouter `
  --model "$ModelId" `
  --mode json `
  $McpFlag
```
* Где `$McpFlag = "--no-mcp"` для режима Baseline, и пустая строка для режима KI-Enabled.

---

## 5. Чек-лист готовности Фазы 1
- [ ] Контейнер `pi-secure` пересобран без ошибок.
- [ ] Проверена версия Pi внутри контейнера: `docker run --rm pi-secure --version` выдаёт 1.0+.
- [ ] Протестирован тестовый запуск с флагом `--no-mcp`.
- [ ] Протестирован нативный коннект к `supergateway` через SSE: тулы `ki_list`, `ki_search` отображаются в каталоге Pi без использования сторонних адаптеров.

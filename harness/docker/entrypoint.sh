#!/bin/bash
set -e

PI_HOME="/home/agent/.pi"
EXTENSIONS_FILE="/pi-extensions.txt"

# Principle of Least Privilege: 
# Redirect "global" installs to a user-owned directory in the persistent volume.
export NPM_CONFIG_PREFIX="$PI_HOME/npm-global"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
mkdir -p "$NPM_CONFIG_PREFIX"

# Extension update detection
EXT_HASH_FILE="$PI_HOME/.extensions.hash"
CURRENT_HASH=$(md5sum "$EXTENSIONS_FILE" | cut -d' ' -f1)
LAST_HASH=""
[ -f "$EXT_HASH_FILE" ] && LAST_HASH=$(cat "$EXT_HASH_FILE")

if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
    echo ""
    echo "=== Pi Docker: Extension changes detected ==="
    echo "Updating Pi extensions..."
    echo ""

    if [ -f "$EXTENSIONS_FILE" ]; then
        while IFS= read -r raw_ext; do
            # Remove CR if file has CRLF endings
            ext=$(echo "$raw_ext" | tr -d '\r')
            # Skip comments and empty lines
            [[ "$ext" =~ ^#.*$ ]] && continue
            [[ -z "$ext" ]] && continue

            echo "  -> Processing: $ext"
            # pi install is idempotent usually, but we force it if needed
            pi install "$ext" || echo "  WARNING: Failed to install $ext"
        done < "$EXTENSIONS_FILE"
        echo "$CURRENT_HASH" > "$EXT_HASH_FILE"
    fi

    echo ""
    echo "=== Extensions processed. ==="
    echo ""
fi

echo ""
echo "Pi Docker Environment ready."
echo "  Project : /app"
echo "  CodeGraph: /codegraph"
echo "  Pi home : $PI_HOME"
echo ""
echo "MCP servers available via host.docker.internal (run start_mcp.ps1 on host)."
echo "  Plannotator: http://localhost:19432"
echo "  Pi Web UI  : http://localhost:19433"
echo ""

if [ "$1" = "bash" ]; then
    echo "Opening Bash shell..."
    shift
    exec /bin/bash "$@"
else
    echo "Starting Pi Agent..."
    exec pi "$@"
fi

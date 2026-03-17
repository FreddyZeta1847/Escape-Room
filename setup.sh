#!/usr/bin/env bash
set -euo pipefail

POPOCHIU_VERSION="v2.1.0"
POPOCHIU_ZIP="popochiu-${POPOCHIU_VERSION}.zip"
POPOCHIU_URL="https://github.com/carenalgas/popochiu/releases/download/${POPOCHIU_VERSION}/${POPOCHIU_ZIP}"
ADDONS_DIR="addons/popochiu"

if [ -d "$ADDONS_DIR" ]; then
    echo "Popochiu already installed at ${ADDONS_DIR}, skipping download."
else
    echo "Downloading Popochiu ${POPOCHIU_VERSION}..."
    curl -L -o "$POPOCHIU_ZIP" "$POPOCHIU_URL"

    echo "Extracting addons/popochiu/..."
    mkdir -p addons
    unzip -q "$POPOCHIU_ZIP" "addons/popochiu/*" -d .

    echo "Cleaning up..."
    rm -f "$POPOCHIU_ZIP"

    echo "Popochiu installed successfully!"
fi

echo ""
echo "Next steps:"
echo "  1. Open the project in Godot 4.6"
echo "  2. Go to Project > Project Settings > Plugins and enable Popochiu"
echo "  3. Run the Popochiu setup wizard (select GUI templates, point-and-click)"
echo "  4. Install an Ollama model: ollama pull phi3:mini"
echo "  5. Start Ollama: ollama serve"

# Escape Room AI - Setup Guide

## Prerequisites

- **Godot 4.6** (standard build)
- **Ollama** (https://ollama.ai) for local LLM inference
- **curl** and **unzip** (Linux/macOS) or **curl** and **PowerShell** (Windows)

## Quick Start

### 1. Download Popochiu Plugin

**Linux / macOS:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows:**
```cmd
setup.bat
```

This downloads and extracts the Popochiu v2.1.0 plugin into `addons/popochiu/`.

### 2. Configure Godot

1. Open the project in Godot 4.6
2. Go to **Project > Project Settings > Plugins**
3. Enable the **Popochiu** plugin
4. Run the Popochiu setup wizard when prompted:
   - Select GUI templates
   - Choose **point-and-click** adventure style

### 3. Set Up Ollama

```bash
ollama pull phi3:mini
ollama serve
```

Ollama must be running on `localhost:11434` for NPC conversations to work. The game will show fallback dialogue if Ollama is unreachable.

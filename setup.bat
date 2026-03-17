@echo off
setlocal

set POPOCHIU_VERSION=v2.1.0
set POPOCHIU_ZIP=popochiu-%POPOCHIU_VERSION%.zip
set POPOCHIU_URL=https://github.com/carenalgas/popochiu/releases/download/%POPOCHIU_VERSION%/%POPOCHIU_ZIP%
set ADDONS_DIR=addons\popochiu

if exist "%ADDONS_DIR%" (
    echo Popochiu already installed at %ADDONS_DIR%, skipping download.
    goto :next_steps
)

echo Downloading Popochiu %POPOCHIU_VERSION%...
curl -L -o "%POPOCHIU_ZIP%" "%POPOCHIU_URL%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to download Popochiu. Make sure curl is available.
    exit /b 1
)

echo Extracting addons\popochiu\...
if not exist addons mkdir addons
powershell -Command "Expand-Archive -Path '%POPOCHIU_ZIP%' -DestinationPath '_popochiu_tmp' -Force"
xcopy /E /I /Y "_popochiu_tmp\addons\popochiu" "%ADDONS_DIR%" >nul
rmdir /S /Q "_popochiu_tmp"

echo Cleaning up...
del /F /Q "%POPOCHIU_ZIP%"

echo Popochiu installed successfully!

:next_steps
echo.
echo Next steps:
echo   1. Open the project in Godot 4.6
echo   2. Go to Project ^> Project Settings ^> Plugins and enable Popochiu
echo   3. Run the Popochiu setup wizard (select GUI templates, point-and-click)
echo   4. Install an Ollama model: ollama pull phi3:mini
echo   5. Start Ollama: ollama serve

endlocal

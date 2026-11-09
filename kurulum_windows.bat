@echo off
chcp 65001 >nul
title Yargi ve UYAP Mevzuat MCP - Otomatik Kurulum

echo ================================================================
echo    Yargi ve UYAP Mevzuat MCP - Windows Kurulum Baslatiliyor...  
echo ================================================================
echo.

set "SCRIPT_DIR=%~dp0"

if exist "%SCRIPT_DIR%install.ps1" (
    echo [1/2] Yerel kurulum betigi calistiriliyor...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & '%SCRIPT_DIR%install.ps1'"
) else if exist "%SCRIPT_DIR%kurulum_windows.ps1" (
    echo [1/2] Yerel baslatici calistiriliyor...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; & '%SCRIPT_DIR%kurulum_windows.ps1'"
) else (
    echo [BILGI] Yerel kurulum dosyalari bulunamadi (tek dosya calistirildi).
    echo         Guncel kurulum GitHub uzerinden otomatik baslatiliyor...
    echo.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex"
)

if %ERRORLEVEL% neq 0 (
    echo.
    echo [HATA] Kurulum sirasinda bir sorun olustu (Hata kodu: %ERRORLEVEL%).
    echo Lutfen internet baglantinizi ve PowerShell izinlerinizi kontrol edin.
)

echo.
pause

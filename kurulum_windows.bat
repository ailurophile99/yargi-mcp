@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Yargi ve UYAP Mevzuat MCP - Kurulum
color 0F

echo ================================================================
echo    Yargi ve UYAP Mevzuat MCP - Windows Kurulumu
echo ================================================================
echo.
echo  Bu pencere kurulum bitene kadar acik kalacak.
echo  Internet hizina gore 2-5 dakika surebilir.
echo.

set "YARGI_FROM_BAT=1"
if not defined TEMP set "TEMP=%USERPROFILE%"
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" set "PSEXE=powershell.exe"
set "LOCAL_PS1=%~dp0install.ps1"
set "TMP_PS1=%TEMP%\yargi_install_%RANDOM%.ps1"
set "URL=https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1"

if exist "%TMP_PS1%" del /f /q "%TMP_PS1%" >nul 2>&1

echo [*] Guncel kurulum betigi GitHub uzerinden indiriliyor...
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; (New-Object Net.WebClient).DownloadFile($env:URL, $env:TMP_PS1) } catch { Write-Host ('    Indirme uyarisi: ' + $_.Exception.Message); exit 3 }"
if exist "%TMP_PS1%" findstr /c:"Install-YargiMcp" "%TMP_PS1%" >nul 2>&1
if exist "%TMP_PS1%" if not errorlevel 1 goto run_tmp
if exist "%TMP_PS1%" del /f /q "%TMP_PS1%" >nul 2>&1

where curl.exe >nul 2>&1
if not errorlevel 1 curl.exe -fsSL --retry 2 "%URL%" -o "%TMP_PS1%" >nul 2>&1
if exist "%TMP_PS1%" findstr /c:"Install-YargiMcp" "%TMP_PS1%" >nul 2>&1
if exist "%TMP_PS1%" if not errorlevel 1 goto run_tmp
if exist "%TMP_PS1%" del /f /q "%TMP_PS1%" >nul 2>&1

echo.
if not exist "%LOCAL_PS1%" goto no_internet
echo [*] Internet uzerinden alinamadi, yerel install.ps1 kullaniliyor...
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_PS1%"
set "RC=%ERRORLEVEL%"
goto finish

:run_tmp
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS1%"
set "RC=%ERRORLEVEL%"
if exist "%TMP_PS1%" del /f /q "%TMP_PS1%" >nul 2>&1
goto finish

:no_internet
echo [HATA] Kurulum betigi indirilemedi.
echo        Internet baglantinizi kontrol edip bu dosyaya tekrar cift tiklayin.
set "RC=1"
goto finish

:finish
echo.
if "%RC%"=="0" goto success
echo ----------------------------------------------------------------
echo  Kurulum tamamlanamadi. Hata kodu: %RC%
echo  Bu pencerenin fotografini cekip gonderebilirsiniz.
echo ----------------------------------------------------------------
goto end

:success
echo  Kurulum bitti. Yapay zeka uygulamanizi tamamen kapatip yeniden acin.

:end
echo.
echo Pencereyi kapatmak icin bir tusa basin...
pause >nul
endlocal

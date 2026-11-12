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
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" set "PSEXE=powershell.exe"
set "LOCAL_PS1=%~dp0install.ps1"
set "URL=https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1"

echo [*] Guncel kurulum betigi GitHub uzerinden indiriliyor...
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; $s = (New-Object Net.WebClient).DownloadString($env:URL) } catch { Write-Host ('    Indirme hatasi: ' + $_.Exception.Message); exit 3 }; . ([ScriptBlock]::Create($s))"
set "RC=%ERRORLEVEL%"
if "%RC%"=="3" goto try_local
goto finish

:try_local
echo.
if not exist "%LOCAL_PS1%" goto no_internet
echo [*] Internet uzerinden alinamadi, yerel install.ps1 kullaniliyor...
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%LOCAL_PS1%"
set "RC=%ERRORLEVEL%"
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

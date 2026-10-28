@echo off
chcp 65001 >nul
title Yargi ve UYAP Mevzuat MCP - Otomatik Kurulum
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0kurulum_windows.ps1"
echo.
pause

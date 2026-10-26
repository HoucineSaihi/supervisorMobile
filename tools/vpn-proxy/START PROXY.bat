@echo off
REM Double-click launcher: starts the API proxy for Android testing.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-api-proxy.ps1"

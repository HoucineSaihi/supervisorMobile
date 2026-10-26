@echo off
REM Double-click launcher: removes the API proxy.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0undo-api-proxy.ps1"

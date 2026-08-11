@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0verify_release.ps1" %*
exit /b %errorlevel%

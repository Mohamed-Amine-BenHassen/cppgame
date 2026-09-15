@echo off
REM Tower of Turing launcher - avoids PowerShell execution-policy friction.
where pwsh >nul 2>&1
if %errorlevel%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1" %*
)

@echo off
REM ===============================================================
REM  Modo Mentor - Sync from Claude Design handoff
REM  Duplo-clique aqui depois de baixar o ZIP do claude.ai/design
REM ===============================================================
setlocal
cd /d "%~dp0"

echo.
echo  Modo Mentor - sync com claude.ai/design
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-from-handoff.ps1" %*

echo.
pause

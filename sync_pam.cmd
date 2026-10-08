@echo off
rem One-click sync for Research-PAM. Double-click at start and end of work. See tools\README in the sync guide, section 6.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\sync_pam.ps1"
pause

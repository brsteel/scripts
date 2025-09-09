@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\Check-VRSetup.ps1"
pause

@echo off
echo Clearing ALL Unity cache...

REM Global Unity cache
rmdir /s /q "%LOCALAPPDATA%\Unity\cache" 2>nul
rmdir /s /q "%APPDATA%\Unity" 2>nul

REM Unity Hub cache
rmdir /s /q "%APPDATA%\UnityHub" 2>nul
rmdir /s /q "%LOCALAPPDATA%\UnityHub" 2>nul

REM Project cache (run from project root)
rmdir /s /q "Library" 2>nul
rmdir /s /q "Temp" 2>nul
rmdir /s /q "obj" 2>nul
rmdir /s /q "Logs" 2>nul

REM Package cache
rmdir /s /q "%APPDATA%\Unity\Asset Store-5.x" 2>nul

echo Unity cache cleared completely!
echo Restart Unity for full effect.
pause

@echo off
echo ====================================================
echo      Scanalyze - Developer Auto-Start Script
echo ====================================================
echo.

echo [1/2] Starting Python Backend on Port 5000...
start "Scanalyze Backend API" cmd /k "cd backend && py run.py"
timeout /t 2 /nobreak >nul

echo [2/2] Establishing secure USB Tunnel for Android...
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:5000 tcp:5000

if %ERRORLEVEL% equ 0 (
    echo.
    echo SUCCESS: USB Tunnel established perfectly!
    echo Your Android phone can now reach the Python backend at 127.0.0.1:5000.
    echo You can now press "Run" in your Flutter IDE.
) else (
    echo.
    echo ERROR: Could not establish USB Tunnel. 
    echo Please make sure your phone is plugged in via USB and unlocked.
)

echo.
pause

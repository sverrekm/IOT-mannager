@echo off
REM Windows batch script for å pushe til GitHub

echo ========================================
echo IoT Manager - Push til GitHub
echo ========================================
echo.

REM Sjekk om git er installert
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo FEIL: Git er ikke installert!
    echo Last ned fra: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [1/4] Initialiserer git repository...
git init

echo.
echo [2/4] Legger til alle filer...
git add .

echo.
echo [3/4] Committer filer...
git commit -m "Initial commit: IoT Manager installer for Raspberry Pi 5"

echo.
echo [4/4] Kobler til GitHub og pusher...
git remote add origin https://github.com/sverrekm/IOT-mannager.git
git branch -M main
git push -u origin main

echo.
echo ========================================
echo Ferdig! Filene er lastet opp til GitHub
echo ========================================
echo.
echo Test installasjonen på Raspberry Pi med:
echo curl -fsSL https://raw.githubusercontent.com/sverrekm/IOT-mannager/main/install.sh ^| bash
echo.
pause

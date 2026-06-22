@echo off
echo.
echo ============================================
echo  Artemis Business OS - Local Test Server
echo ============================================
echo.

REM Check if backend is already running
netstat -ano | findstr :4040 >nul
if %errorlevel% == 0 (
  echo [OK] Backend already running on port 4040
) else (
  echo [1/2] Starting backend on port 4040...
  start "Artemis Backend" /min cmd /c "cd /d C:\Users\Abiyu\Documents\Artemis\backend && set PORT=4040 && node dist/main.js > server-test.log 2>&1"
  timeout /t 5 /nobreak >nul
)

REM Check if web server is already running
netstat -ano | findstr :8080 >nul
if %errorlevel% == 0 (
  echo [OK] Web server already running on port 8080
) else (
  echo [2/2] Starting Flutter web on port 8080...
  start "Artemis Web" /min cmd /c "cd /d C:\Users\Abiyu\Documents\Artemis\backend && node scripts\serve-web.js > serve-web.log 2>&1"
  timeout /t 2 /nobreak >nul
)

echo.
echo ============================================
echo  Open in your browser:
echo    http://localhost:8080
echo.
echo  Login:
echo    admin@artemis.com / admin123
echo    sales@artemis.com  / user123
echo.
echo  Swagger API docs:
echo    http://localhost:4040/api/docs
echo ============================================
echo.
pause
@echo off
setlocal
cd /d "S:\bank_microservices\microservicesWithMysql-4\accounts"
if errorlevel 1 (
  > "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\accounts.done" echo 1
  exit /b 1
)
call mvn compile jib:dockerBuild > "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\accounts.log" 2>&1
set "RC=%ERRORLEVEL%"
> "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\accounts.done" echo %RC%
exit /b %RC%

@echo off
setlocal
cd /d "S:\bank_microservices\microservicesWithMysql-4\configserver"
if errorlevel 1 (
  > "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\configserver.done" echo 1
  exit /b 1
)
call mvn compile jib:dockerBuild > "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\configserver.log" 2>&1
set "RC=%ERRORLEVEL%"
> "S:\bank_microservices\microservicesWithMysql-4\build-scripts\.build-logs\configserver.done" echo %RC%
exit /b %RC%

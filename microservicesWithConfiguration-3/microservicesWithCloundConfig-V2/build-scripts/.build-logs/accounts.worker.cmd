@echo off
setlocal
cd /d "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\accounts"
if errorlevel 1 (
  > "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\accounts.done" echo 1
  exit /b 1
)
call mvn compile jib:build > "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\accounts.log" 2>&1
set "RC=%ERRORLEVEL%"
> "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\accounts.done" echo %RC%
exit /b %RC%

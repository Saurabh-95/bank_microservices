@echo off
setlocal
cd /d "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\cards"
if errorlevel 1 (
  > "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\cards.done" echo 1
  exit /b 1
)
call mvn compile jib:build > "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\cards.log" 2>&1
set "RC=%ERRORLEVEL%"
> "S:\bank_microservices\microservicesWithConfiguration-3\microservicesWithCloundConfig-V2\build-scripts\.build-logs\cards.done" echo %RC%
exit /b %RC%

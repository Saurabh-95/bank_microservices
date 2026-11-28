@echo off
setlocal
cd /d "S:\bank_microservices\microservicesWithDiscoveryRegistryLoadbalancer-5\loans"
if errorlevel 1 (
  > "S:\bank_microservices\microservicesWithDiscoveryRegistryLoadbalancer-5\build-scripts\.build-logs\loans.done" echo 1
  exit /b 1
)
call mvn compile jib:dockerBuild > "S:\bank_microservices\microservicesWithDiscoveryRegistryLoadbalancer-5\build-scripts\.build-logs\loans.log" 2>&1
set "RC=%ERRORLEVEL%"
> "S:\bank_microservices\microservicesWithDiscoveryRegistryLoadbalancer-5\build-scripts\.build-logs\loans.done" echo %RC%
exit /b %RC%

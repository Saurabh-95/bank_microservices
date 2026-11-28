@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==========================================================
rem Build selected microservice images with Maven Jib.
rem
rem Usage:
rem   build-images.cmd
rem   build-images.cmd accounts cards
rem   build-images.cmd --parallel
rem   build-images.cmd -p accounts cards
rem   build-images.cmd --push
rem   build-images.cmd -p --push cards
rem
rem Default: jib:dockerBuild (build into local Docker daemon)
rem --push:  jib:build (build and push to registry configured in pom)
rem ==========================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fI"

set "ALL_SERVICES=configserver accounts loans cards eurekaserver"
set "SERVICES=%ALL_SERVICES%"
set "PARALLEL=0"
set "PUSH=0"
set "ARGS="

rem Parse options and optional service names.
for %%A in (%*) do (
    if /I "%%~A"=="--parallel" (
        set "PARALLEL=1"
    ) else if /I "%%~A"=="-p" (
        set "PARALLEL=1"
    ) else if /I "%%~A"=="--push" (
        set "PUSH=1"
    ) else if /I "%%~A"=="--help" (
        goto usage
    ) else if /I "%%~A"=="-h" (
        goto usage
    ) else (
        set "ARGS=!ARGS! %%~A"
    )
)

if defined ARGS set "SERVICES=!ARGS:~1!"

rem Validate service names.
for %%S in (%SERVICES%) do (
    set "VALID=0"
    for %%V in (%ALL_SERVICES%) do (
        if /I "%%S"=="%%V" set "VALID=1"
    )
    if "!VALID!"=="0" (
        echo ERROR: Unknown service "%%S".
        echo Valid services: %ALL_SERVICES%
        exit /b 2
    )
)

if "%PUSH%"=="1" (
    set "JIB_GOAL=jib:build"
    set "ACTION=built and pushed"
) else (
    set "JIB_GOAL=jib:dockerBuild"
    set "ACTION=built locally"
)

set "LOG_DIR=%SCRIPT_DIR%.build-logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo Project: "%PROJECT_ROOT%"
echo Services: %SERVICES%
echo Mode: %ACTION%
if "%PARALLEL%"=="1" echo Build execution: parallel
if "%PARALLEL%"=="0" echo Build execution: sequential
echo.

if "%PARALLEL%"=="1" (
    call :build_parallel
) else (
    call :build_sequential
)
set "FINAL_RC=%ERRORLEVEL%"
exit /b %FINAL_RC%


:build_sequential
set "FAILED=0"

for %%S in (%SERVICES%) do (
    echo.
    echo ==========================================================
    echo Building %%S
    echo ==========================================================

    if not exist "%PROJECT_ROOT%\%%S\pom.xml" (
        echo ERROR: "%PROJECT_ROOT%\%%S\pom.xml" was not found.
        set "FAILED=1"
    ) else (
        pushd "%PROJECT_ROOT%\%%S"
        call mvn compile %JIB_GOAL%
        set "RC=!ERRORLEVEL!"
        popd

        if not "!RC!"=="0" (
            echo FAILED: %%S - exit code !RC!
            set "FAILED=1"
        ) else (
            echo SUCCESS: %%S
        )
    )
)

if "!FAILED!"=="0" (
    echo.
    echo All requested images %ACTION% successfully: %SERVICES%
    exit /b 0
)

echo.
echo One or more builds failed.
exit /b 1


:build_parallel
rem Delete old completion markers for this run.
del /q "%LOG_DIR%\*.done" 2>nul

rem Create a separate worker script for every selected service.
for %%S in (%SERVICES%) do (
    if not exist "%PROJECT_ROOT%\%%S\pom.xml" (
        echo ERROR: "%PROJECT_ROOT%\%%S\pom.xml" was not found.
        > "%LOG_DIR%\%%S.done" echo 1
        > "%LOG_DIR%\%%S.log" echo Service pom.xml was not found.
    ) else (
        > "%LOG_DIR%\%%S.worker.cmd" (
            echo @echo off
            echo setlocal
            echo cd /d "%PROJECT_ROOT%\%%S"
            echo if errorlevel 1 ^(
            echo   ^> "%LOG_DIR%\%%S.done" echo 1
            echo   exit /b 1
            echo ^)
            echo call mvn compile %JIB_GOAL% ^> "%LOG_DIR%\%%S.log" 2^>^&1
            echo set "RC=%%ERRORLEVEL%%"
            echo ^> "%LOG_DIR%\%%S.done" echo %%RC%%
            echo exit /b %%RC%%
        )
    )
)

rem Launch workers using a separate cmd.exe process.
for %%S in (%SERVICES%) do (
    if exist "%LOG_DIR%\%%S.worker.cmd" (
        echo Starting %%S - log: "%LOG_DIR%\%%S.log"
        start "build-%%S" /B "%ComSpec%" /D /C ""%LOG_DIR%\%%S.worker.cmd""
    )
)

rem Wait for all selected services to write a completion marker.
:wait_loop
set "PENDING=0"
for %%S in (%SERVICES%) do (
    if not exist "%LOG_DIR%\%%S.done" set "PENDING=1"
)

if "!PENDING!"=="1" timeout /t 2 /nobreak >nul
if "!PENDING!"=="1" goto wait_loop

rem Check each worker's exit code.
set "FAILED="
for %%S in (%SERVICES%) do (
    set "RESULT="
    set /p RESULT=<"%LOG_DIR%\%%S.done"
    if not "!RESULT!"=="0" (
        set "FAILED=!FAILED! %%S"
        echo FAILED: %%S - exit code !RESULT!. See "%LOG_DIR%\%%S.log"
    ) else (
        echo SUCCESS: %%S
    )
)

if not defined FAILED (
    echo.
    echo All requested images %ACTION% successfully: %SERVICES%
    exit /b 0
)

echo.
echo Build FAILED for:%FAILED%
echo See logs in "%LOG_DIR%".
exit /b 1


:usage
echo Usage:
echo   %~nx0 [--parallel^|-p] [--push] [configserver] [accounts] [loans] [cards]
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 -p
echo   %~nx0 -p accounts cards
echo   %~nx0 --push
echo   %~nx0 -p --push cards
exit /b 0

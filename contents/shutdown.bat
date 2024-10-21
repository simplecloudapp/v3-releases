@echo off
setlocal

REM Define patterns that uniquely identify your Java processes
set controller_pattern=controller-runtime
set serverhost_pattern=serverhost-runtime

REM Gracefully stop Java processes
call :stop_java_process "%controller_pattern%"
call :stop_java_process "%serverhost_pattern%"

goto :eof

REM Function to gracefully stop a Java process based on a pattern
:stop_java_process
set pattern=%~1
echo Attempting to gracefully terminate Java processes with pattern "%pattern%".


REM Find unique process IDs matching the pattern and terminate them
for /f "tokens=3 delims=," %%i in ('wmic process where "name='java.exe'" get ProcessId^,CommandLine /format:csv ^| findstr /i "%pattern%"') do (
    cmd /c "taskkill /PID %%i /T /F"
)

exit /b
goto :eof

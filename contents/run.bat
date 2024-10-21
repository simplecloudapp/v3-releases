@echo off
setlocal

REM ===== User-customizable variables =====

REM Controller variables
set controller_database_url=jdbc:sqlite:database.db
set controller_host=0.0.0.0
set controller_grpc_port=5816
set controller_pubsub_port=5817

REM Server host variables
set serverhost_id=internal-server-host
set serverhost_host=0.0.0.0
set serverhost_port=5820

REM ===== End of user-customizable variables =====

REM ONLY CHANGE FOLLOWING VARIABLES IF YOU KNOW WHAT YOU ARE DOING

REM Determine the full path to the script's directory
set SCRIPT_DIR=%~dp0

REM Paths and commands
set auth_secret_path=%SCRIPT_DIR%\.secrets\auth.secret
set libs_dir=%SCRIPT_DIR%\libs

REM Controller session variables
set controller_session=controller-runtime
set controller_dir=%SCRIPT_DIR%\controller
set controller_group_path=%SCRIPT_DIR%\groups
set controller_launcher=%controller_dir%\controller-runtime.jar
set controller_cmd=java -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -jar %controller_launcher% --database-url="%controller_database_url%" --grpc-host="%controller_host%" --grpc-port="%controller_grpc_port%" --pub-sub-grpc-port="%controller_pubsub_port%" --group-path="%controller_group_path%" --auth-secret-path="%auth_secret_path%"

REM Server host session variables
set serverhost_session=serverhost-runtime
set serverhost_dir=%SCRIPT_DIR%\droplets\serverhost
set serverhost_running_servers_path=%SCRIPT_DIR%\running
set serverhost_template_path=%SCRIPT_DIR%\templates
set serverhost_launcher=%serverhost_dir%\serverhost-runtime.jar
set serverhost_cmd=java -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -jar %serverhost_launcher% --host-id="%serverhost_id%" --host-ip="%serverhost_host%" --host-port="%serverhost_port%" --grpc-host="%controller_host%" --grpc-port="%controller_grpc_port%" --pub-sub-grpc-host="%controller_host%" --pub-sub-grpc-port="%controller_pubsub_port%" --libs-path="%libs_dir%" --running-servers-path="%serverhost_running_servers_path%" --template-path="%serverhost_template_path%" --auth-secret-path="%auth_secret_path%"

REM Start the controller if not already running
call :start_window_if_not_running "%controller_session%" "%controller_dir%" %controller_cmd%

REM Start the serverhost if not already running
call :start_window_if_not_running "%serverhost_session%" "%serverhost_dir%" %serverhost_cmd%

goto :eof

:start_window_if_not_running
setlocal
set session_name=%1
shift
set directory=%1
shift

REM Concatenate all remaining arguments to form the command
set command=
:concat_arguments
if "%1"=="" goto run_command
set command=%command% %1
shift
goto concat_arguments

:run_command
REM Check if window (session) is already running using tasklist and window title comparison
for /f "tokens=3 delims=," %%i in ('wmic process where "name='java.exe'" get ProcessId^,CommandLine /format:csv 2^>nul ^| findstr /i "%session_name%"') do (
    echo %session_name% already running...
    goto :eof
)
echo Starting %session_name%...
start %session_name% cmd /c "cd /d %directory% && %command% && pause"
goto :eof

endlocal

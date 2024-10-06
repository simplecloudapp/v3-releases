#!/bin/bash

# Determine the full path to the script's directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Navigate to the script's directory
cd "$SCRIPT_DIR"

# Function to start screen if not already running
start_screen_if_not_running() {
  local session_name=$1
  local directory=$2
  local command=$3

  if screen -list | grep -q "\.$session_name"; then
    echo "Screen session '$session_name' already running."
  else
    echo "Starting $session_name..."
    screen -dmS "$session_name" bash -c "cd $directory && exec $command"
  fi
}

# Define your sessions and commands here
auth_secret_path="$SCRIPT_DIR/.secrets/auth.secret"  # Adjust this path or variable as needed
libs_path="$SCRIPT_DIR/libs"

controller_session="simplecloud-controller"
controller_dir="$SCRIPT_DIR/controller"
controller_group_path="$SCRIPT_DIR/groups"
controller_launcher="app.simplecloud.controller.runtime.launcher.LauncherKt"
controller_cmd="java -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:CompileThreshold=100 -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -cp \"$libs_path/*:.\" $controller_launcher --group-path=\"$controller_group_path\" --auth-secret-path=\"$auth_secret_path\""

serverhost_session="simplecloud-serverhost"
serverhost_dir="$SCRIPT_DIR/droplets/serverhost"
serverhost_running_servers_path="$SCRIPT_DIR/running"
serverhost_template_path="$SCRIPT_DIR/templates"
serverhost_launcher="app.simplecloud.droplet.serverhost.runtime.launcher.LauncherKt"
serverhost_cmd="java -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:CompileThreshold=100 -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -cp \"$libs_path/*:.\" $serverhost_launcher --libs-path=\"$libs_path\" --running-servers-path=\"$serverhost_running_servers_path\" --template-path=\"$serverhost_template_path\" --auth-secret-path=\"$auth_secret_path\""

# Start the controller if not already running
start_screen_if_not_running "$controller_session" "$controller_dir" "$controller_cmd"

# Start the serverhost droplet if not already running
start_screen_if_not_running "$serverhost_session" "$serverhost_dir" "$serverhost_cmd"

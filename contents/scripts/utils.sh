#!/bin/bash

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

stop_java_process() {
  local pattern=$1
  echo "Stopping Java process with pattern '$pattern'."
  pkill -f "$pattern"
}

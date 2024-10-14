#!/bin/bash

# Function to gracefully stop a Java process
stop_java_process() {
  local pattern=$1
  echo "Attempting to gracefully terminate Java process with pattern '$pattern'."
  pkill -f "$pattern"
}

# Define patterns that uniquely identify your Java processes
controller_pattern="controller-runtime.jar"
serverhost_pattern="serverhost-runtime.jar"

# Gracefully stop Java processes
stop_java_process "$controller_pattern"
stop_java_process "$serverhost_pattern"

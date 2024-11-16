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

run_auto_updater() {
  local auto_updater_jar=$1
  local application_config=$2
  local versions_config=$3
  local current_version_file=$4
  local channel=$5
  local allow_major_updates=$6

  echo "Running auto-updater..."
    local cmd=("java" "-jar" "$auto_updater_jar"
               "--application-config=$application_config"
               "--versions-config=$versions_config"
               "--current-version-file=$current_version_file"
               "--channel=$channel")

    if [ "$allow_major_updates" = true ]; then
      cmd+=("--allow-major-updates")
    fi

    "${cmd[@]}"
}
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

run_auto_updater() {
  local auto_updater_jar=$1
  local application_config=$2
  local versions_config=$3
  local current_version_file=$4
  local channel=$5
  local allow_major_updates=$6

  echo "Running auto-updater..."
    local cmd=("java" "-jar" "$auto_updater_jar"
               "--application-config=$application_config"
               "--versions-config=$versions_config"
               "--current-version-file=$current_version_file"
               "--channel=$channel")

    if [ "$allow_major_updates" = true ]; then
      cmd+=("--allow-major-updates")
    fi

    "${cmd[@]}"
}

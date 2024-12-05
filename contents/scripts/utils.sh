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

  local jar_dir=$(dirname "$(readlink -f "$auto_updater_jar")")

  echo "Running auto-updater..."
  pushd "$jar_dir" > /dev/null || exit 1

  local cmd=("java" "-jar" "$auto_updater_jar"
             "--application-config=$application_config"
             "--versions-config=$versions_config"
             "--current-version-file=$current_version_file"
             "--channel=$channel")

  if [ "$allow_major_updates" = true ]; then
    cmd+=("--allow-major-updates")
  fi

  "${cmd[@]}"

  popd > /dev/null
}

get_component_status() {
    local process_pattern=$1
    local session_name=$2
    local config_path=$3
    local current_version_file=$4

    local pid=$(pgrep -f "$process_pattern" | head -n1)
    local running=false
    local uptime=""
    local memory=""
    local current_version=""

    if [ -n "$pid" ]; then
        running=true

        if [[ "$OSTYPE" == "darwin"* ]]; then
            uptime=$(ps -p $pid -o etime | tail -n1 | tr -d ' ')
            memory=$(ps -p $pid -o rss | tail -n1 | awk '{printf "%.1f", $1/1024}')
        else
            uptime=$(ps -p $pid -o etime= | tr -d ' ')
            memory=$(ps -p $pid -o rss= | awk '{printf "%.1f", $1/1024}')
        fi

        if [ -f "$current_version_file" ]; then
            current_version=$(cat "$current_version_file")
        fi
    fi

    cat << EOF
{
    "running": $running,
    "pid": $([ -n "$pid" ] && echo "\"$pid\"" || echo "null"),
    "uptime": $([ -n "$uptime" ] && echo "\"$uptime\"" || echo "null"),
    "memory_usage_mb": $([ -n "$memory" ] && echo "$memory" || echo "null"),
    "current_version": $([ -n "$current_version" ] && echo "\"$current_version\"" || echo "null"),
    "screen_session": "$session_name",
    "config_path": "$config_path"
}
EOF
}

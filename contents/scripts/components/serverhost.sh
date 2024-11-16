#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
source "$ROOT_DIR/scripts/utils.sh"

serverhost_session="simplecloud-serverhost"
serverhost_dir="$ROOT_DIR/droplets/serverhost"
serverhost_launcher="$serverhost_dir/serverhost-runtime.jar"

serverhost_cmd="java -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:CompileThreshold=100 -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -jar $serverhost_launcher"

case "$1" in
  start)
    start_screen_if_not_running "$serverhost_session" "$serverhost_dir" "$serverhost_cmd"
    ;;
  stop)
    stop_java_process "serverhost-runtime.jar"
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

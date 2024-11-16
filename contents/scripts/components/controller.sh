#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(dirname "$(dirname "$SCRIPT_DIR")")
source "$ROOT_DIR/scripts/utils.sh"

controller_session="simplecloud-controller"
controller_dir="$ROOT_DIR/controller"
controller_launcher="$controller_dir/controller-runtime.jar"

controller_cmd="java -XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:CompileThreshold=100 -XX:+UnlockExperimentalVMOptions -XX:+UseCompressedOops -Xmx512m -Xms256m -jar $controller_launcher"

case "$1" in
  start)
    start_screen_if_not_running "$controller_session" "$controller_dir" "$controller_cmd"
    ;;
  stop)
    stop_java_process "controller-runtime.jar"
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

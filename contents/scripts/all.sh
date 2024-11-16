#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
COMPONENTS_DIR="$SCRIPT_DIR/components"

if [[ "$1" != "start" && "$1" != "stop" ]]; then
  echo "Usage: $0 {start|stop}"
  exit 1
fi

for script in "$COMPONENTS_DIR"/*.sh; do
  if [[ -x "$script" ]]; then
    echo "Executing $script $1"
    "$script" "$1"
  else
    echo "Skipping $script as it is not executable"
  fi
done

#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
COMPONENTS_DIR="$SCRIPT_DIR/components"

# Initialize associative array without declare -A for older bash versions
was_running=""

get_all_components_status() {
    first=true
    echo "{"
    echo "    \"components\": ["

    for script in "$COMPONENTS_DIR"/*.sh; do
        if [[ -x "$script" ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi

            component_name=$(basename "$script" .sh)
            component_status=$("$script" status | sed 's/^/        /')

            echo "        {"
            echo "            \"name\": \"$component_name\","
            echo "            \"data\": $component_status"
            echo -n "        }"
        fi
    done

    echo
    echo "    ]"
    echo "}"
}

get_components_status() {
    first=true
    echo "{"
    echo "    \"components\": ["

    for script in "$COMPONENTS_DIR"/*.sh; do
        if [[ -x "$script" ]]; then
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            component_name=$(basename "$script" .sh)
            status=$("$script" status)
            is_running=$(echo "$status" | grep -q '"running": true' && echo "true" || echo "false")
            config_path=$(echo "$status" | grep -o '"config_path": "[^"]*"' | cut -d'"' -f4)
            was_running_value=$(echo "$was_running" | grep -q "$component_name" && echo "true" || echo "false")
            echo "        {"
            echo "            \"name\": \"$component_name\","
            echo "            \"running\": $is_running,"
            echo "            \"was_already_running\": $was_running_value,"
            echo "            \"config_path\": \"$config_path\""
            echo -n "        }"
        fi
    done

    echo
    echo "    ]"
    echo "}"
}

verify_all_running() {
    for script in "$COMPONENTS_DIR"/*.sh; do
        if [[ -x "$script" ]]; then
            status=$("$script" status)
            if ! echo "$status" | grep -q '"running": true'; then
                return 1
            fi
        fi
    done
    return 0
}

check_running_state() {
    was_running=""
    for script in "$COMPONENTS_DIR"/*.sh; do
        if [[ -x "$script" ]]; then
            component_name=$(basename "$script" .sh)
            status=$("$script" status 2>/dev/null)
            if echo "$status" | grep -q '"running": true'; then
                was_running="${was_running}${component_name} "
            fi
        fi
    done
}

case "$1" in
    start)
        check_running_state >/dev/null 2>&1

        for script in "$COMPONENTS_DIR"/*.sh; do
            if [[ -x "$script" ]]; then
                component_name=$(basename "$script" .sh)
                if ! echo "$was_running" | grep -q "$component_name"; then
                    "$script" "start" >/dev/null 2>&1
                fi
            fi
        done

        for i in {1..5}; do
            if verify_all_running; then
                get_components_status
                exit 0
            fi
            [ $i -lt 5 ] && sleep 1
        done

        get_components_status
        ;;
    stop)
        for script in "$COMPONENTS_DIR"/*.sh; do
            [[ -x "$script" ]] && "$script" "stop" >/dev/null 2>&1
        done
        ;;
    status)
        get_all_components_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}" >&2
        exit 1
        ;;
esac

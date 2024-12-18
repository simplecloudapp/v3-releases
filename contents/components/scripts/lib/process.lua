local M = {}

-- Detect OS
local function is_windows()
    return package.config:sub(1,1) == '\\'
end

function M.file_exists(path)
    local file = io.open(path, "r")
    if file then file:close() return true end
    return false
end

function M.sleep(ms)
    if is_windows() then
        os.execute("timeout /t " .. math.ceil(ms/1000) .. " /nobreak >nul")
    else
        os.execute("sleep " .. (ms / 1000))
    end
end

function M.run_command(cmd)
    local handle = io.popen(cmd .. (is_windows() and " 2>&1" or " 2>&1"))
    if not handle then return false end
    handle:read("*a")
    local success = handle:close()
    return success ~= nil
end

function M.is_process_running(pattern)
    local cmd
    if is_windows() then
        cmd = string.format('wmic process where "commandline like \'%%%s%%\'" get processid', pattern)
    else
        cmd = "pgrep -f " .. pattern
    end

    local handle = io.popen(cmd)
    if handle then
        local output = handle:read("*a")
        handle:close()

        if is_windows() then
            -- Skip header line and get first PID
            local pid = output:match("\r\n(%d+)")
            return pid ~= nil, pid
        else
            local pid = output:match("(%d+)")
            return pid ~= nil, pid
        end
    end
    return false, nil
end

function M.is_screen_running(session_name)
    if is_windows() then
        -- Windows doesn't use screen, check for running Java process instead
        return M.is_process_running(session_name)
    else
        local handle = io.popen("screen -ls")
        if handle then
            local output = handle:read("*a")
            handle:close()
            return output:match(string.format("[%d]+%.%s", session_name)) ~= nil
        end
    end
    return false
end

function M.start_process(session_name, work_dir, command, jar_path)
    if not (session_name and work_dir and command and jar_path) then
        return false, false
    end

    local is_running, _ = M.is_process_running(jar_path)
    local screen_running = M.is_screen_running(session_name)

    if is_running or screen_running then
        return false, true
    end

    if not M.file_exists(jar_path) then
        return false, false
    end

    local full_command
    if is_windows() then
        -- Create and use a batch file for Windows
        local bat_path = work_dir .. "\\" .. session_name .. ".bat"
        local bat_content = string.format("@echo off\ncd /d %s\nstart /b %s", work_dir, command)
        local bat_file = io.open(bat_path, "w")
        if bat_file then
            bat_file:write(bat_content)
            bat_file:close()
            full_command = string.format("start /b \"\" %s", bat_path)
        else
            return false, false
        end
    else
        full_command = string.format(
            "cd %s && screen -dmS %s bash -c '%s'",
            work_dir, session_name, command
        )
    end

    if not M.run_command(full_command) then
        return false, false
    end

    return true, false
end

function M.stop_process(pattern)
    if is_windows() then
        M.run_command(string.format('taskkill /F /FI "COMMANDLINE like %%%s%%" /T', pattern))
    else
        M.run_command("pkill -f " .. pattern)
    end
    return true
end

function M.get_process_info(pattern, session_name, config_path)
    local info = {
        running = false,
        pid = nil,
        uptime = nil,
        memory_usage_mb = nil,
        current_version = nil,
        screen_session = session_name,
        config_path = config_path
    }

    local is_running, pid = M.is_process_running(pattern)
    if not is_running then return info end

    info.running = true
    info.pid = pid

    local cmd
    if is_windows() then
        -- Get memory usage (Working Set Size)
        cmd = string.format('wmic process where processid="%s" get WorkingSetSize', pid)
        local handle = io.popen(cmd)
        if handle then
            local output = handle:read("*a")
            handle:close()
            local mem = output:match("\r\n(%d+)")
            if mem then
                info.memory_usage_mb = tonumber(mem) / (1024 * 1024)  -- Convert bytes to MB
            end
        end

        -- Get process start time
        cmd = string.format('wmic process where processid="%s" get CreationDate', pid)
        local handle = io.popen(cmd)
        if handle then
            local output = handle:read("*a")
            handle:close()
            local creation_time = output:match("\r\n(%d%d%d%d%d%d%d%d%d%d%d%d%d%d%.%d%d%d%d%d%d)")
            if creation_time then
                -- Convert Windows timestamp to uptime string
                info.uptime = "00:00:00" -- TODO: Implement proper time calculation
            end
        end
    else
        -- Unix systems
        local handle = io.popen("ps -p " .. pid .. " -o rss=")
        if handle then
            local mem = handle:read("*l")
            handle:close()
            if mem then
                info.memory_usage_mb = tonumber(mem) / 1024
            end
        end

        handle = io.popen("ps -p " .. pid .. " -o etime=")
        if handle then
            info.uptime = handle:read("*l")
            handle:close()
        end
    end

    -- Version file reading works the same on both systems
    local version_file = string.format("%s/current_version.txt",
        string.match(config_path, "(.-)[/\\][^/\\]*$"))
    local vh = io.open(version_file)
    if vh then
        info.current_version = vh:read("*l")
        vh:close()
    end

    return info
end

return M

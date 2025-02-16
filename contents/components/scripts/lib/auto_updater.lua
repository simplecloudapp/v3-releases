local json = require("json")
local os = require("os")

local M = {}

-- Function to check and clean stale lock files
local function clean_stale_lock(file_path)
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*a")
        file:close()

        -- Verify that we have valid content
        local timestamp = tonumber(content)
        if not timestamp then
            -- If timestamp is invalid, remove the corrupted lock file
            os.remove(file_path)
            return true
        end

        local current_time = os.time()
        -- Check if file is older than 2 minutes (120 seconds)
        if current_time - timestamp > 120 then
            os.remove(file_path)
            return true
        end
    end
    return false
end

local function is_updater_updating(auto_updater_dir)
    local update_lock_file = auto_updater_dir .. "/update.lock"

    -- Clean stale lock file if it exists
    if clean_stale_lock(update_lock_file) then
        return false
    end

    local file = io.open(update_lock_file, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function set_updater_lock(auto_updater_dir, lock)
    local update_lock_file = auto_updater_dir .. "/update.lock"
    if lock then
        local file = io.open(update_lock_file, "w")
        if file then
            file:write(tostring(os.time()))
            file:close()
        end
    else
        os.remove(update_lock_file)
    end
end

local function can_update(auto_updater_dir)
    local last_update_file = auto_updater_dir .. "/last_updated.txt"
    local current_time = os.time()

    -- Clean stale last_updated file if it exists
    clean_stale_lock(last_update_file)

    -- Check if last_updated.txt exists
    local file = io.open(last_update_file, "r")
    if file then
        local content = file:read("*a")
        file:close()

        local last_update_time = tonumber(content)
        if not last_update_time then
            -- If timestamp is invalid, allow update
            return true
        end

        local time_diff = current_time - last_update_time
        if time_diff < 300 then
            return false
        end
    end

    -- Update the timestamp
    file = io.open(last_update_file, "w")
    if file then
        file:write(tostring(current_time))
        file:close()
    end

    return true
end

function M.update_self(root_dir)
    local auto_updater_dir = root_dir .. "/components/auto-updater"

    -- Check if enough time has passed since last update
    if not can_update(auto_updater_dir) then
        return true  -- Return true to not block component updates
    end

    -- Create a temporary directory with a more reliable approach
    local temp_dir = os.tmpname()
    os.remove(temp_dir)  -- Remove the temp file
    temp_dir = temp_dir .. "_dir"  -- Add _dir suffix to make it unique

    -- Create directory and ensure it exists
    local mkdir_result = os.execute("mkdir -p " .. temp_dir)
    if not mkdir_result then
        print("Failed to create temp directory: " .. temp_dir)
        return false
    end

    -- Copy with error checking
    local copy_result = os.execute(string.format("cp '%s/auto-updater.jar' '%s/'", auto_updater_dir, temp_dir))
    if not copy_result then
        print("Failed to copy auto-updater.jar to temp directory")
        os.execute("rm -rf " .. temp_dir)
        return false
    end

    -- Set update lock
    set_updater_lock(auto_updater_dir, true)

    local cmd = string.format(
            "cd %s && java -jar %s/auto-updater.jar --application-config=%s/application.yml --current-version-file=%s/current_version.txt --channel=snapshots",
            temp_dir,
            temp_dir,
            auto_updater_dir,
            auto_updater_dir
    )

    if os.getenv("SC_GITHUB_TOKEN") then
        cmd = "SC_GITHUB_TOKEN=" .. os.getenv("SC_GITHUB_TOKEN") .. " " .. cmd
    end

    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        set_updater_lock(auto_updater_dir, false)
        os.execute("rm -rf " .. temp_dir)
        return false
    end

    local output = handle:read("*a")
    local success = handle:close()

    -- If update was successful, copy the new jar back
    if success then
        os.execute(string.format("cp -r '%s/'* '%s/'", temp_dir, auto_updater_dir))
    end

    -- Cleanup
    os.execute("rm -rf " .. temp_dir)
    set_updater_lock(auto_updater_dir, false)

    return success ~= nil
end

function M.update(config)
    local auto_updater_dir = ROOT_DIR .. "/components/auto-updater"
    local initial_sleep = 1
    local attempt = 0

    while is_updater_updating(auto_updater_dir) do
        local sleep_time = initial_sleep * (attempt + 1)
        os.execute("sleep " .. sleep_time)
        attempt = attempt + 1
    end

    if not M.update_self(ROOT_DIR) then
        return false
    end

    local cmd = string.format(
            "cd %s && java -jar %s --application-config=%s --current-version-file=%s --channel=snapshots",
            config.component_dir,
            config.auto_updater_jar,
            config.config_file,
            config.version_file
    )

    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        return false
    end

    local output = handle:read("*a")
    local success = handle:close()

    return success ~= nil
end

return M

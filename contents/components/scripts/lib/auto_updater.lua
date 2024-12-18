local json = require("json")
local os = require("os")

local M = {}

local function can_update(auto_updater_dir)
    local last_update_file = auto_updater_dir .. "/last_updated.txt"
    local current_time = os.time()

    -- Check if last_updated.txt exists
    local file = io.open(last_update_file, "r")
    if file then
        local last_update_time = tonumber(file:read("*a"))
        file:close()

        local time_diff = current_time - last_update_time
        if time_diff < 300 then
            return false
        end
    else
    end

    -- Update the timestamp
    file = io.open(last_update_file, "w")
    if file then
        file:write(tostring(current_time))
        file:close()
    else
    end

    return true
end

function M.update_self(root_dir)
    local auto_updater_dir = root_dir .. "/components/auto-updater"

    -- Check if enough time has passed since last update
    if not can_update(auto_updater_dir) then
        return true  -- Return true to not block component updates
    end

    local cmd = string.format(
            "cd %s && java -jar %s/auto-updater.jar --application-config=%s/application.yml --versions-config=%s/versions.yml --current-version-file=%s/current_version.txt --channel=dev --allow-major-updates",
            auto_updater_dir,
            auto_updater_dir,
            auto_updater_dir,
            auto_updater_dir,
            auto_updater_dir
    )

    if os.getenv("SC_GITHUB_TOKEN") then
        cmd = "SC_GITHUB_TOKEN=" .. os.getenv("SC_GITHUB_TOKEN") .. " " .. cmd
    end

    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        return false
    end

    local output = handle:read("*a")
    local success = handle:close()

    return success ~= nil
end

function M.update(config)
    -- First update the auto-updater itself
    if not M.update_self(ROOT_DIR) then
        return false
    end

    -- Then update the component
    local cmd = string.format(
            "cd %s && java -jar %s --application-config=%s --versions-config=%s --current-version-file=%s --channel=dev --allow-major-updates",
            config.component_dir,
            config.auto_updater_jar,
            config.config_file,
            config.versions_config,
            config.version_file
    )

    if config.github_token then
        cmd = "SC_GITHUB_TOKEN=" .. config.github_token .. " " .. cmd
    end

    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
        return false
    end

    local output = handle:read("*a")
    local success = handle:close()

    return success ~= nil
end

return M

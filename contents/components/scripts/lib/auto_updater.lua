local json = require("json")

local M = {}

function M.update_self(root_dir)
    local auto_updater_dir = root_dir .. "/components/auto-updater"
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
    if not handle then return false end
    handle:read("*a")
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
    if not handle then return false end
    handle:read("*a")
    local success = handle:close()
    return success ~= nil
end

return M

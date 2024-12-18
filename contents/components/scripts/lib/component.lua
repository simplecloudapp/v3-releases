-- lib/component.lua
local json = require("json")
local process = require("process")
local auto_updater = require("auto_updater")

local M = {}

function M.create(config)
    if not config or not config.name or not config.session or not config.jar then
        error("Invalid component configuration")
    end

    local component = {}

    -- Default Java options if not provided
    config.java_opts = config.java_opts or {
        "-XX:+UseG1GC",
        "-XX:MaxGCPauseMillis=50",
        "-XX:CompileThreshold=100",
        "-XX:+UnlockExperimentalVMOptions",
        "-XX:+UseCompressedOops",
        "-Xmx512m",
        "-Xms256m"
    }

    function component.start(root_dir)
        if not root_dir then
            return json.encode({
                components = {
                    {
                        name = config.name,
                        running = false,
                        was_already_running = false,
                        config_path = ""
                    }
                }
            })
        end

        local component_dir = root_dir .. "/components/" .. config.name
        local jar_path = component_dir .. "/" .. config.jar
        local config_path = component_dir .. "/application.yml"

        auto_updater.update({
            component_dir = component_dir,
            version_file = component_dir .. "/current_version.txt",
            versions_config = root_dir .. "/components/auto-updater/versions.yml",
            config_file = config_path,
            auto_updater_jar = root_dir .. "/components/auto-updater/auto-updater.jar",
            github_token = os.getenv("SC_GITHUB_TOKEN")
        })

        local java_cmd = string.format(
            "java %s -jar %s",
            table.concat(config.java_opts, " "),
            jar_path
        )

        local success, was_running = process.start_process(config.session, component_dir, java_cmd, jar_path)
        local info = process.get_process_info(config.jar, config.session, config_path)

        return json.encode({
            components = {
                {
                    name = config.name,
                    running = info.running,
                    was_already_running = was_running,
                    config_path = config_path
                }
            }
        })
    end

    function component.stop()
        process.stop_process(config.jar)
        return json.encode({ success = true })
    end

    function component.status()
        local info = process.get_process_info(
            config.jar,
            config.session,
            ROOT_DIR .. "/components/" .. config.name .. "/application.yml"
        )

        return json.encode({
            components = {
                {
                    name = config.name,
                    data = info
                }
            }
        })
    end

    return component
end

return M

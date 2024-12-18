local json = require("json")
local auto_updater = require("auto_updater")

local M = {}

function M.create(config)
    if not config or not config.name or not config.session then
        error("Invalid component configuration")
    end

    if not config.jar and not config.command then
        error("Either jar or command must be provided")
    end

    local component = {}

    -- Default Java options if jar is specified
    if config.jar then
        config.java_opts = config.java_opts or {
            "-XX:+UseG1GC",
            "-XX:MaxGCPauseMillis=50",
            "-XX:CompileThreshold=100",
            "-XX:+UnlockExperimentalVMOptions",
            "-XX:+UseCompressedOops",
            "-Xmx512m",
            "-Xms256m"
        }
    end

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
        local config_path = component_dir .. "/application.yml"

        -- Run auto-updater if this is a Java component
        if config.jar then
            auto_updater.update({
                component_dir = component_dir,
                version_file = component_dir .. "/current_version.txt",
                versions_config = root_dir .. "/components/auto-updater/versions.yml",
                config_file = config_path,
                auto_updater_jar = root_dir .. "/components/auto-updater/auto-updater.jar",
                github_token = os.getenv("SC_GITHUB_TOKEN")
            })
        end

        local cmd, process_id, executable_path
        if config.jar then
            local jar_path = component_dir .. "/" .. config.jar
            cmd = string.format(
                    "java %s -jar %s",
                    table.concat(config.java_opts, " "),
                    jar_path
            )
            process_id = jar_path
            executable_path = jar_path
        else
            cmd = config.command
            process_id = config.name
            executable_path = config_path
        end

        -- Using directly exposed process functions from Go
        local success, was_running = process.start_process(config.session, component_dir, cmd, executable_path)
        local info = process.get_process_info(process_id, config.session, config_path)

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
        -- Using directly exposed process function from Go with the correct process identifier
        local process_id = config.jar or config.name
        process.stop_process(process_id, config.session)
        return json.encode({ success = true })
    end

    function component.status()
        -- Using directly exposed process function from Go
        local process_id = config.jar or config.name
        local info = process.get_process_info(
                process_id,
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
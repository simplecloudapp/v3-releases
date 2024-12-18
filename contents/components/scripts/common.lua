local json = require("json")
local os = require("os")

-- Global variables
ROOT_DIR = ROOT_DIR or os.getenv("ROOT_DIR")

-- Common utilities
function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

function write_file(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Export common functions
return {
    read_file = read_file,
    write_file = write_file
}

local component = require("component")

return component.create({
    name = "metrics",
    session = "simplecloud-metrics",
    jar = "metrics-runtime.jar"
})

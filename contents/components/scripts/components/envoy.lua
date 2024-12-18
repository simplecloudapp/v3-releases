local component = require("component")

return component.create({
    name = "envoy",
    session = "simplecloud-envoy",
    command = "envoy -c envoy-bootstrap.yaml"
})
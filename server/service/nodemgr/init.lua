local skynet = require "skynet"
local s = require "service"

local service_cache = {}

s.resp.newservice = function (source, name, ...)
    local srv = skynet.newservice(name, ...)
    return srv
end

s.start(...)
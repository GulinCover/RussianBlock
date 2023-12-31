local Skynet = require "skynet"
local runconfig = require "runconfig"
local skynet_manager = require "skynet.manager"
local cluster = require "skynet.cluster"

Skynet.start(function ()
    skynet.error("[start main]")

    local mynode = skynet.getenv("node")
    local nodecfg = runconfig[mynode]

    local nodemgr = skynet.newservice("nodemgr", "nodemgr", 0)
    skynet.name("nodemgr", nodemgr)

    local mysql = skynet.newservice("mysql", "mysql", 0)
    skynet.name("mysql", mysql)

    for i, v in pairs(nodecfg.gateway or {}) do
        local srv = skynet.newservice("gateway", "gateway", i)
        skynet.name("gateway"..i, srv)
    end

    for i, v in pairs(nodecfg.login or {}) do
        local srv = skynet.newservice("login", "login", i)
        skynet.name("login"..i, srv)
    end

    local anode = runconfig.agentmgr.node
    if mynode == anode then
        local srv = skynet.newservice("agentmgr", "agentmgr", 0)
        skynet.name("agentmgr", srv)
    else
        local proxy = cluster.proxy(anode, "agentmgr")
        skynet.name("agentmgr", proxy)
    end
    skynet.exit()
end)
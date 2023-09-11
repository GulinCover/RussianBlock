local skynet = require "skynet"
local cluster = require "skynet.cluster"
local cjson = require "cjson"

local Service = {
    --类型和id
    name = "",
    id = 0,
    --回调函数
    exit = nil,
    init = nil,
    --分发方法
    resp = {},
}

local traceback = function(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

local dispatch = function(session, address, cmd, ...)
    local func = Service.resp[cmd]
    if not func then
        skynet.ret()
        return
    end

    local ret = table.pack(xpcall(func, traceback, address, ...))
    if not ret[1] then
        skynet.ret()
        return
    end

    skynet.retpack(table.unpack(ret, 2))
end

local init = function()
    skynet.dispatch("lua", dispatch)
    if Service.init then
        Service.init()
    end
end

function Service.log(msg)
    local now = os.date("%Y-%m-%d %H:%:M:%S")
    skynet.error(now.." ["..Service.name.."] "..Service.id.." "..msg)
end

function Service.call(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.call(srv, "lua", ...)
    else
        return cluster.call(node, srv, ...)
    end
end

function Service.send(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, ...)
    end
end

function Service.start(name, id, ...)
    Service.name = name
    Service.id = tonumber(id)
    skynet.start(init)
end

function Service.json_result(code, msg, data)
    local m = {
        code = code,
        msg = msg,
        data = data
    }
    return cjson.encode(m)
end

function Service.json_ret(code_msg, data)
    local m = {
        code = code_msg[1],
        msg = code_msg[2],
        data = data
    }
    return cjson.encode(m)
end

function Service.to_json(obj)
    return cjson.encode(obj)
end

return Service
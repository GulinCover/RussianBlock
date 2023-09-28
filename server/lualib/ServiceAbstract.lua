local skynet = require "skynet"
local cluster = require "skynet.cluster"
local Instruction = require "Instruction"

local Service = {
    --类型和id
    name = "",
    id = 0,
    node = nil,
    hybrid = nil,
    --回调函数
    Construct = nil,
    Destroy = nil,
    --分发方法
    resp = {},
    internal = {},
    --拦截器
    interceptList = {},
}

local Traceback = function(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

local Dispatch = function(session, address, cmd, ...)
    local type = Instruction.CMD_INTERNAL_TYPE
    if ... and ...["commandType"] then
        type = ...["commandType"]
    end
    local func = Service[type][cmd]
    if not func then
        skynet.ret()
        return
    end

    local ret = table.pack(xpcall(func, Traceback, address, ...))
    if not ret[1] then
        skynet.ret()
        return
    end

    skynet.retpack(table.unpack(ret, 2))
end

local Construct = function()
    skynet.dispatch("lua", Dispatch)
    if Service.Construct then
        Service.Construct()
    end
end

function Service.AddIntercept(intercept)
    if intercept then
        if not intercept.Order then
            intercept.Order = 0
        end

        table.insert(Service.interceptList, intercept)

        -- 排序
        local len = #this.interceptList
        for i = 1, len do
            for j = 1, len - i do
                if this.interceptList[j].Order < this.interceptList[j+1].Order then
                    local temp = this.interceptList[j]
                    this.interceptList[j] = this.interceptList[j+1]
                    this.interceptList[j+1] = temp
                end
            end
        end
    end
end

function Service.Log(msg)
    local now = os.date("%Y-%m-%d %H:%:M:%S")
    skynet.error(now.." ["..Service.name.."] "..Service.id.." "..msg)
end

function Service.Call(node, srv, ...)
    local myNode = skynet.getenv("node")
    if node == myNode then
        return skynet.call(srv, "lua", ...)
    else
        return cluster.call(node, srv, "lua", ...)
    end
end

function Service.Send(node, srv, ...)
    local myNode = skynet.getenv("node")
    if node == myNode then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, "lua", ...)
    end
end

function Service.SendRemoteDestroy(node, srv)
    Service.Send(node, srv)
end

function Service.CallRemoteDestroy(node, srv)
    Service.Call(node, srv)
end

function Service.Destroy()
    skynet.exit()
end

function Service.SendToClient(source, command)
    Service.Send(source.node, source.hybrid, Instruction.Gateway.Internal.CMD_SEND_DATA, command)
end

function Service.Start(name, id, ...)
    Service.name = name
    Service.id = tonumber(id)
    Service.node = skynet.getenv("node")
    Service.hybrid = Service.name..Service.id
    skynet.start(Construct)
end

-- 销毁
Service.internal[Instruction.CMD_EXIT] = function(source)
    Service.Destroy()
end

-- 添加拦截器
Service.internal[Instruction.CMD_ADD_INTERCEPT] = function(source, intercept)
    Service.AddIntercept(intercept)
end

-- 添加拦截器
Service.CallAddIntercept = function(node, hybrid, intercept)
    Service.Call(node, hybrid, Instruction.CMD_ADD_INTERCEPT, intercept)
end

return Service
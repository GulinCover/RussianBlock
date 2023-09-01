local skynet = require "skynet"
local s = require "service"

function Status()
    return {
        score = 0,
        coords = {},
    }
end

local gateway = nil
local status = nil

s.client = {}

-- 同步数据
s.client.update = function(source, data)
    status.score = data.score
    status.coords = data.coords
end

-- 用户下线
s.resp.kick = function(source)
    status = nil
    s.log("user kick")
end

-- 服务退出
s.resp.exit = function(source)
    s.log("service exit")
    skynet.exit()
end

-- 消息分发
s.resp.client = function(source, cmd, msg)
    gateway = source
    if s.client[cmd] then
        local ret_msg = s.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", s.id, ret_msg)
        end
    else
        skynet.error("s.resp.client fail", cmd)
    end
end

-- 构造函数
s.init = function()
    status = Status()
end

s.start(...)
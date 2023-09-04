local skynet = require "skynet"
local s = require "service"
local params = require "params"

function Status()
    return {
        user_id = nil,
        score = 0,
        coords = {},
    }
end

local gateway = nil
local status = nil
local heart_packet = nil

s.client = {}

-- 心跳检测
local heart_check = function()
    while true do
        -- 单位秒
        if not heart_packet then
            local now = os.time()
            s.log("[".. status.user_id .."] heart check start")
            heart_packet = params.HeartPacket()
            heart_packet.id = status.user_id
            heart_packet.timestamp = now
            local r = math.random(1, 10000000)
            heart_packet.random = r
        end

        skynet.call(gateway, "lua", "send_heart_check", heart_packet)
        if not receive_heart_packet or receive_heart_packet.timestamp ~= now or receive_heart_packet.random ~= r + 1 then
            s.log("[".. status.user_id .."] heart check failed")
            -- 心跳检测异常,强制下线
        end
        s.log("[".. status.user_id .."] heart check end")
        -- 单位1/100秒
        skynet.sleep(0.5*100)
    end
end

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
    skynet.fork(heart_check)
end

s.start(...)
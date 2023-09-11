local skynet = require "skynet"
local s = require "service"
local run_config = require "runconfig"

-- 全局唯一

STATUS = {
    LOGIN = 2,
    LOGIN_COMPETE = 3,
    GAME = 4,
    LOGOUT = 5,
    LOGIN_EXCEPTION = 6
}

local players = {}

function Player()
    local m = {
        user_id = nil,
        node = nil,
        agent = nil,
        status = nil,
        gate = nil
    }
    return m
end

-- 登录
s.resp.reqlogin = function (source, auto_login_params)
    local user = players[auto_login_params.user_id]

    -- 已登录
    if user then
        s.log("reqlogin fail, already login "..auto_login_params.user_id)
        return nil
    end

    -- 未登录则自动登录
    local player = Player()
    player.user_id = auto_login_params.user_id
    player.node = auto_login_params.node
    player.gate = auto_login_params.gateway
    player.agent = nil
    player.status = STATUS.LOGIN
    players[auto_login_params.user_id] = player
    local agent = s.call(auto_login_params.node, "nodemgr", "newservice", "agent", "agent", auto_login_params.user_id)
    player.status = STATUS.LOGIN_COMPETE
    if not agent then
        player.status = STATUS.LOGIN_EXCEPTION
    end
    player.agent = agent
    return agent
end

-- 踢出下线
s.resp.reqkick = function (source, user_id, reason)
    local user = players[user_id]

    if not user then
        return false
    end

    -- 正在游戏中无法下线
    if user.status ~= STATUS.GAME then
        s.send(user.node, user.agent, "mark_kick")
        return false
    end

    local node = user.node
    local agent = user.agent
    local gateway = user.gateway
    user.status = STATUS.LOGOUT

    s.call(node, agent, "kick")
    s.send(node, agent, "exit")
    s.send(node, gateway, "kick", user_id)
    players[user_id] = nil

    if reason then
        s.log(reason)
    end

    return true
end

s.start(...)
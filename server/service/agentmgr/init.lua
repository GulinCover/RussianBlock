local skynet = require "skynet"
local s = require "service"
local run_config = require "runconfig"

STATUS = {
    LOGIN = 2,
    LOGIN_COMPETE = 3,
    GAME = 4,
    LOGOUT = 5
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
    local mplayer = players[auto_login_params.user_id]

    -- 已登录
    if mplayer then
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
    local agent = s.call(node, "nodemgr", "newservice", "agent", "agent", auto_login_params.user_id)
    player.agent = agent
    player.status = STATUS.LOGIN_COMPETE
    return agent
end

s.resp.reqkick = function (source, user_id, reason)
    local mplayer = players[user_id]

    if not mplayer then
        return false
    end

    if mplayer.status ~= STATUS.GAME then
        return false
    end

    local pnode = mplayer.node
    local pagent = mplayer.agent
    local gateway = mplayer.gateway
    mplayer.status = STATUS.LOGOUT

    s.call(pnode, pagent, "kick")
    s.send(pnode, pagent, "exit")
    s.send(pnode, gateway, "kick", user_id)
    players[user_id] = nil

    return true
end

s.start(...)
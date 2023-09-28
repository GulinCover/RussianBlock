local skynet = require "skynet"
local AgentMgrService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local Instruction = require "Instruction"

-- 全局唯一
local this = AgentMgrService

STATUS = {
    LOGIN = 2,
    LOGIN_COMPETE = 3,
    GAME = 4,
    LOGOUT = 5,
    LOGIN_EXCEPTION = 6
}

local PlayerItem = function ()
    local m = {
        user_id = nil,
        node = nil,
        agent = nil,
        status = nil,
        gate = nil
    }
    return m
end
AgentMgrService.agentCache = {}

-- 登录
AgentMgrService.internal[Instruction.AgentMgr.Internal.CMD_REQ_LOGIN] = function (source, command)
    local user = this.agentCache[command.userId]

    -- 已登录
    if user then
        return nil, "req_login fail, already login "..command.user_id
    end

    -- 未登录则自动登录
    local player = PlayerItem()
    player.userId = command.userId
    player.node = command.node
    player.gate = command.gateway
    player.agent = nil
    player.status = STATUS.LOGIN
    this.agentCache[command.userId] = player
    local param = {
        service = "agent",
        name = "agent",
        id = command.user_id
    }
    local hr, agent = this.Call(command.node, "nodemgr", Instruction.NodeMgr.Internal.CMD_NEW_SERVICE, param)
    player.status = STATUS.LOGIN_COMPETE
    if not hr then
        player.status = STATUS.LOGIN_EXCEPTION
    end
    player.agent = agent
    return hr, agent
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

this.Start(...)
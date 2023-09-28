local skynet = require "skynet"
local AgentService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local Instruction = require "Instruction"
local ServiceUtils = require "ServiceUtils"
local Error = require "Error"
local SysUserMapper = require "mapper.SysUserMapper"

local this = AgentService

SubCommand = {
    Match = "match",
}

this.ChatInfo = {
    chat = nil,
    node = nil,
}

this.RoomInfo = {
    room = nil,
    node = nil,
}

this.SceneInfo = {
    sceneId = nil,
    scene = nil,
    node = nil,
    currentScore = 0,
    coords = {},
    nextBlock = {},
}

this.UserInfo = {
    heartCheckTime = nil,
    matchStatus = {0,0},
    friendList = {},
    rankNum = 0,
}

this.ServiceInfo = {
    gateway = nil,
}

-- 数据解析
AgentService.DataAnalysis = function(data)
    return ServiceUtils.FromJson(data)
end

-- 普通数据同步
AgentService.CommonSync = function(data)

end

-- 战斗数据同步
AgentService.SceneSync = function(data)
    if not this.SceneInfo.scene then
        return
    end

    -- 同步自身
    this.SceneInfo.currentScore = data.currentScore
    this.SceneInfo.coords = data.coords
    this.SceneInfo.nextBlock = data.nextBlock

    -- 发送给场景计算
    local command = {
        command = Instruction.Scene.Internal.CMD_DATA_SYNC,
        userId = this.id,
        data = this.SceneInfo
    }
    this.Send(this.SceneInfo.node, this.SceneInfo.scene, Instruction.Scene.Internal.CMD_DATA_SYNC, command)
end

-- 通知游戏开始
AgentService.internal[Instruction.Agent.Internal.CMD_START_GAME] = function(source)
    local command = {
        userId = this.UserInfo.userId,
        command = Instruction.Agent.CMD_START_GAME,
    }
    this.Send(this.node, this.ServiceInfo.gateway, Instruction.Gateway.Internal.CMD_SEND_DATA, command)
end

-- 匹配完成
AgentService.internal[Instruction.Agent.CMD_COMPETE_MATCH] = function(source, param)
    local command = {
        userId = this.UserInfo.userId,
        command = Instruction.Agent.CMD_COMPETE_MATCH,
        data = {
            scene = param.scene,
            node = param.node
        }
    }
    this.SceneInfo.sceneId = param.sceneId
    this.SceneInfo.scene = param.scene
    this.SceneInfo.node = param.node
    this.Send(this.node, this.ServiceInfo.gateway, Instruction.Gateway.Internal.CMD_SEND_DATA, command)
end

-- 数据同步
AgentService.internal[Instruction.Agent.Internal.CMD_UPDATE_DATA] = function(source)
    local data = {

    }
    this.Send(this.node, this.ServiceInfo.gateway, Instruction.Gateway.Internal.CMD_SEND_DATA, data)
end

-- 对局完成实体化数据,更新数据
AgentService.internal[Instruction.Agent.Internal.CMD_SUBSTANTIALIZE_DATA] = function(source, command)

end

-- 客户端消息分发
AgentService.internal[Instruction.Agent.Internal.CMD_CLIENT] = function(source, command)
    if not this.ServiceInfo.gateway then
        this.ServiceInfo.gateway = command.gateway
    end
    if this.resp[command.command] then
        this.resp[command.command](nil, command)
    else
        this.Log("s.resp.client fail"..cmd)
    end
end

-- 资源加载完毕，开始游戏
AgentService.resp[Instruction.Agent.CMD_START_GAME] = function(source, command)
    local param = {
        userId = this.UserInfo.userId,
    }
    this.Send(command.data.node, command.data.scene, Instruction.Scene.Internal.CMD_START_GAME, param)
end

-- 开始匹配
AgentService.resp[Instruction.Agent.CMD_READY_MATCH] = function(source, command)

end

-- 开始排位
AgentService.resp[Instruction.Agent.CMD_READY_RANK] = function(source, command)
    if this.UserInfo.matchStatus[1] == 0 then
        this.UserInfo.matchStatus[1] = 2
        this.UserInfo.matchStatus[2] = 1
    end

    local command2 = {
        command = Instruction.Agent.CMD_READY_MATCH,
        data = this.UserInfo.matchStatus
    }
    -- 通知前端进入匹配等待界面
    this.SendToClient(command, command2)
    local param = {
        agent = {
            node = this.node,
            agent = this.hybrid,
            UserInfo = this.UserInfo
        }
    }
    this.Send(nil, 'roommgr', Instruction.RoomMgr.Internal.CMD_READY_RANK, param)
end

-- 构造函数
AgentService.Construct = function()
    this.UserInfo.heartCheckTime = os.time()

    -- 查询数据库获取用户信息
    local ret = skynet.call(SysUserMapper.selectSysUserById(this.id))
    if not ret or not ret[1] then
        this.Log("select user_info exception")
        this.Send(RunConfig["agentmgr"].node, "agentmgr", Instruction.AgentMgr.Internal.CMD_KICK_LOGIN, this.id)
        return
    end

    -- 用户参数赋值
    this.UserInfo.rankNum = ret[1].rank_num

    -- 查询好友信息,生成好友chat
    ret = skynet.call(SysUserMapper.selectSysUserFriendById(this.id))
    if not ret or not ret[1] then
        this.Log("select user_friend_info exception")
        return
    end
    this.UserInfo.friendList = ret
end

-- 启动函数
this.Start(...)
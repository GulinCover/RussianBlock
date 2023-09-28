local skynet = require "skynet"
local RoomService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local Instruction = require "Instruction"

local this = RoomService
this.AgentList = {}

local RankMatch = function(agentList)
    -- 反馈前端
    local p = {
        sceneId = id,
        scene = scene,
        node = this.node
    }
    for i, v in ipairs(agentList) do
        this.Send(v.node, v.agent, Instruction.Agent.CMD_COMPETE_MATCH, p)
    end
end

-- 匹配完成
RoomService.internal[Instruction.Room.Internal.CMD_MATCH_COMPLETE] = function(source, command)
    this.AgentList = command.agentList
    if command.type == 1 then
        RankMatch(command.agentList)
    end
end

RoomService.internal[Instruction.Room.Internal.CMD_CONFIRM_MATCH] = function(source, param)
    local flag = param.confirm == 0
    if 0 == param.confirm then
        for k,v in pairs(this.AgentList) do
            if param.agent
        end

        -- 销毁自身
        this.Destroy()
    end

    local id = os.time()
    for i, v in ipairs(agentList) do
        id = '$'..id..v.UserInfo.userId
    end

    -- 匹配完成，生成战斗场景
    local param = {
        id = id,
        node = this.node,
    }
    local hr, scene = this.Call(this.node, 'scenemgr', Instruction.SceneMgr.Internal.CMD_NEW_SCENE, param)
    if not hr then
        this.Log(scene)
        return
    end

    this.Call(this.node, scene, Instruction.Scene.Internal.CMD_AGENT_SYNC, agentList)
end

-- 启动函数
this.Start(...)
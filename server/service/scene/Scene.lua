local skynet = require "skynet"
local SceneService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local Instruction = require "Instruction"
local ServiceUtils = require "ServiceUtils"
local Error = require "Error"

local this = SceneService

local PlayerItem = function()
    return {
        type = 0,
        agent = nil
    }
end

SceneService.Players = {}

-- 服务器战斗场景渲染
SceneService.LoopUpdate = function()

end

SceneService.internal[Instruction.Scene.Internal.CMD_AGENT_SYNC] = function(source, agentList)
    for i, v in pairs(agentList) do
        this.Players[i] = PlayerItem()
        this.Players[i].agent = agentList[i]
    end
end

SceneService.internal[Instruction.Scene.Internal.CMD_START_GAME] = function(source, param)
    local idx = 0
    for i, v in pairs(this.Players) do
        if not v.agent then
            return
        end

        if v.agent.UserInfo.userId == param.userId then
            v.type = 1
        end

        if v.type == 1 then
            idx = idx + 1
        end

        this.Call(v.agent.node, v.agent.agent, Instruction.Agent.CMD_START_GAME)
    end

    -- 开始游戏
    if idx == #this.Players then
        this.LoopUpdate()
    end
end

SceneService.internal[Instruction.Scene.Internal.CMD_DATA_SYNC] = function(source, param)
    for i, v in pairs(this.Players) do
        this.Send(v.agent.node, v.agent.agent, Instruction.Agent.Internal.CMD_UPDATE_DATA)
    end
end

-- 启动函数
this.Start(...)
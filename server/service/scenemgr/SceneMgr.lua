local skynet = require "skynet"
local SceneMgrService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local queue = require "skynet.queue"
local Instruction = require "Instruction"

local this = SceneMgrService

this.SceneCache = {}

SceneMgrService.internal[Instruction.SceneMgr.Internal.CMD_NEW_SCENE] = function(source, param)
    local command = {
        service = 'scene',
        name = 'scene',
        id = param.id
    }
    local hr, scene = this.Call(param.node, 'nodemgr', Instruction.NodeMgr.Internal.CMD_NEW_SERVICE, command)
    if hr then
        this.SceneCache[param.id] = scene
    end
    return hr, scene
end

-- 启动函数
this.Start(...)
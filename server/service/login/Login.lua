local skynet = require "skynet"
local LoginService = require "ServiceAbstract"
local Instruction = require "Instruction"
local RunConfig = require "RunConfig"
local SysUserMapper = require "mapper.SysUserMapper"

local this = LoginService

-- 数据返回
LoginService.internal[Instruction.Login.Internal.CMD_AUTO_LOGIN] = function(source, command)
    local ret = skynet.call(SysUserMapper.selectSysUserByTokenId(command.userId, command.token))
    if not ret or not ret[1] then
        return false, "login failed, not found user["..command.userId.."]"
    end
    return this.Call(RunConfig["agentmgr"].node,"agentmgr", Instruction.AgentMgr.Internal.CMD_REQ_LOGIN, command)
end


this.Start(...)
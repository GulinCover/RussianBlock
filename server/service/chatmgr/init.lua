local skynet = require "skynet"
local s = require "service"
local run_config = require "runconfig"
local params = require "params"

-- 全局唯一
local item = {
    agent = nil
}
local chat_cache = {}
local agent_cache = {}

-- 好友信息发送
s.resp.send_message = function(src, dest, message, type)
    local agent = agent_cache[dest]
    if not agent then
        return
    end
    skynet.send(agent, "lua", "send_chat", src, dest, message, type)
end

s.start(...)
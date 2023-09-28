local skynet = require "skynet"
local s = require "service"
local run_config = require "runconfig"
local params = require "params"

local item = {
    user_id = nil,
    agent = nil,
    node = nil
}

local chat_info = {
    type = nil,
    user_ids = {}
}

-- ·¢ËÍÏûÏ¢
s.resp.send_message = function(u, d, m, t)
    if chat_info.type ~= t then
        return
    end

    for k,v in pairs(chat_info.user_ids) do
        if u ~= v.user_id then
            s.send(v.node, v.agent, "lua", "client", "")
        end
    end
end

s.start(...)
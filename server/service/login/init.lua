local skynet = require "skynet"
local s = require "service"
local error_msg = require "error"
local params = require "params"

-- 自动登录
s.client.auto_login = function (conn, source)
    local gateway = source
    local node = skynet.getenv("node")

    local param = params.AutoLoginParams(conn, node, gateway)
    local agent = skynet.call("agentmgr", "lua", "reqlogin", param)
    if not agent then
        return s.json_ret(error_msg.AGENT_REGISTER_FAIL())
    end

    local hr = skynet.call(source, "lua", "sure_agent", conn, agent)
    if hr then
        return s.json_ret(error_msg.OPERATION_SUCCESS())
    end
    return s.json_ret(error_msg.AGENT_REGISTER_FAIL())
end

-- 消息分发
s.resp.client = function(source, fd, cmd, data)
    if s.client[cmd] then
        local ret_msg = s.client[cmd](data, source)
        skynet.send(source, "lua", "send_json_by_fd", fd, ret_msg)
    else
        skynet.error("s.resp.client fail", cmd)
    end
end

s.start(...)
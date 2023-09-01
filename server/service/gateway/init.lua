local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local run_config = require "runconfig"
local error_msg = require "error"
local instruct = require "instruction"
local common = require "common"
local params = require "params"

local conns = {}   --[fd] = conn
local players = {} --[playerid] = gateplayer

local sys_user_mapper = require "mapper.sys_user"

-- 连接类
function conn()
    local m = {
        fd = nil,
        playerid = nil,
        token = nil
    }
    return m
end

--玩家类
function gateplayer()
    local m = {
        playerid = nil,
        agent = nil,
        conn = nil
    }return m
end

local str_pack = function (cmd, msg)
    return table.concat(msg, ",") .. "\r\n"
end

local disconnect = function (fd)
    local c = conns[fd]
    if not c then
        return
    end

    local playerid = c.playerid

    if not playerid then
        return
    else
        players[playerid] = nil
        local reason = "断线"
        skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
    end
end

local toproto = function (content)
end

local fromproto = function (content)
end

local encrypt = function (content)
end

local decrypt = function (content)
end

local check_is_legal_user = function (playerid, token)
    
end

-- 发送json信息
s.resp.send_json_by_fd = function (source, fd, msg)
    if not conns[fd] then
        return
    end

    local buff = s.json_result(200, msg)
    skynet.error("send fd[" .. fd .. "] cmd["..tostring(instruct.CMD_JSON).."] " .. buff)
    socket.write(fd, "json,"..buff)
end

-- 发送信息
s.resp.send = function(source, playerid, msg)
    local gplayer = players[playerid]
    if gplayer == nil then
        return
    end

    local c = gplayer.conn
    if c == nil then
        return
    end

    s.resp.send_by_fd(nil, c.fd, msg)
end

-- 登出
s.resp.kick = function (source, playerid)
    local gplayer = players[playerid]
    if not gplayer then
        return
    end

    local c = gplayer.conn
    players[playerid] = nil

    if not c then
        return
    end

    conns[c.fd] = nil
    disconnect(c.fd)
    socket.close(c.fd)
end

-- 刷新token
s.resp.update_token = function (source, playerid)
    local ret = skynet.call(sys_user_mapper.selectSysUserById(playerid))

    if not ret or not ret[1] then
        return false
    end

    local conn = conns[playerid]
    if not conn then
        return false
    end

    conn.token = ret[1].token
    return true
end

-- ///////////////////////////////////////////////////////////////////////////////

local connect_cache = {}
local user_cache = {}

-- 拆分指令
local command_unpack = function (instruction)
    local msg = {}

    while true do
        local arg, rest = string.match(instruction, "(.-),(.*)")
        if arg then
            instruction = rest
            table.insert(msg, arg)
        else
            table.insert(msg, instruction)
            break
        end
    end

    if not msg[1] then
        s.log("instruction illegal")
        return nil
    end
    return msg
end

-- 异步返回json信息
local send_error_json = function(code, msg)
    skynet.send(s.name..s.id, "lua", "send_json_by_fd", fd, s.json_result(code, msg))
end

-- 异步返回json信息
local send_err_json = function(code_msg)
    skynet.send(s.name..s.id, "lua", "send_json_by_fd", fd, s.json_ret(code_msg))
end

-- 解析分发指令
local process_msg = function (fd, instruction)
    -- 指令解析
    local instructs = command_unpack(instruction)
    if not instructs then
        send_err_json(error_msg.INSTRUCTION_ERROR())
        return
    end

    s.log("recv fd[" .. fd .. "] cmd[" .. instructs[1] .. "] {" .. instruction .. "}")

    local conn = connect_cache[fd]
    local user_id = conn.user_id

    -- 未登录
    local login_param = params.LoginParams(instructs)
    if not user_id then
        if not login_param then
            send_err_json(error_msg.NOT_LOGIN())
            return
        end

        local ret = skynet.call(sys_user_mapper.selectSysUserByTokenId(login_param.id, login_param.token))
        if not ret or not ret[1] then
            send_err_json(error_msg.NOT_MATCH_LOGIN())
            return
        end

        conn.user_id = ret[1].id
        conn.token = ret[1].token
        local node_cfg = run_config[skynet.getenv("node")]
        local login_server_id = math.random(1, #node_cfg.login)
        local login_server_name = "login"..login_server_id
        -- 执行自动登录,创建agent,自动绑定
        skynet.call(login_server_name, "lua", "client", fd, "auto_login", conn)
    end

    -- token匹配
    if conn.token ~= login_param.token then
        send_err_json(error_msg.NOT_MATCH_LOGIN())
        return
    end

    -- 不能重复执行登录
    if instruct.CMD_AUTO_LOGIN == instructs[1] then
        return
    end

    -- 执行指令
    skynet.send(conn.agent, "lua", "client", instructs)
end

-- 响应buff分割
local process_buff = function(fd, read_buff)
    while true do
        local msg_str, rest = string.match(read_buff, "(.-)\r\n(.*)")
        if msg_str then
            s.log(msg_str)
            read_buff = rest
            process_msg(fd, msg_str)
        else
            return read_buff
        end
    end
end

-- 接收响应
local receive_loop = function(fd)
    socket.start(fd)
    s.log("socket connected " ..fd)
    local read_buff = ""
    while true do
        local receive_buff = socket.read(fd)
        if receive_buff then
            receive_buff = read_buff .. receive_buff
            read_buff = process_buff(fd, read_buff)
        else
            s.log("socket close " ..fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

-- 连接socket回调
local connect = function(fd, address)
    s.log("connect from " .. address .. " " .. fd)
    local field = params.GatewayField(fd)
    connect_cache[fd] = field
    skynet.fork(receive_loop, fd)
end

-- ==================================服务方法=====================================

-- 同步数据
s.resp.sync_data = function (source, conn, data)

end

-- 绑定agent
s.resp.sure_agent = function (source, conn, agent)
    local user_conn = connect_cache[conn.fd]
    -- 若存在表示已经登录
    local user = user_cache[conn.user_id]
    if user then
        s.send_err_json(error_msg.ALREADY_LOGIN())
        return false
    end

    user_conn.agent = agent
    user_cache[conn.user_id] = user_conn
    s.log("user["..user_id.."] bind agent success")
    return true
end

-- 发送信息
s.resp.send_by_fd = function (source, fd, msg)
    if not connect_cache[fd] then
        return
    end

    s.log("send fd[" .. fd .. "] "..msg)
    socket.write(fd, msg.."\r\n")
end

-- 发送json信息
s.resp.send_json_by_fd = function(source, fd, msg)
    if not connect_cache[fd] then
        return
    end

    s.log("send fd[" .. fd .. "] "..msg)
    socket.write(fd, instruct.CMD_JSON..","..msg.."\r\n")
end

-- 发送错误响应信息
s.resp.error = function (source, fd, user_id, msg)
    if not fd then
        local user = user_cache[user_id]
        if not user then
            return
        end

        s.resp.send_by_fd(nil, user.fd, msg)
    end
end

-- 发送json错误响应信息
s.resp.error_json = function (source, fd, user_id, msg)
    if not fd then
        local user = user_cache[user_id]
        if not user then
            return
        end

        s.resp.send_json_by_fd(nil, user.fd, msg)
    end
end

-- 构造函数
function s.init()
    s.log("start")
    local node = skynet.getenv("node")
    local node_cfg = run_config[node]
    local port = node_cfg.gateway[s.id].port
    local listen_fd = socket.listen("0.0.0.0", port)
    s.log("Listen socket :", "0.0.0.0", port)
    socket.start(listen_fd, connect)
end

s.start(...)
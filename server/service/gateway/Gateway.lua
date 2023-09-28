local skynet = require "skynet"
local GatewayService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local ServiceUtils = require "utils.ServiceUtils"
local Instruction = require "Instruction"
local Error = require "Error"

local this = GatewayService

local ConnectCacheItem = function(fd)
    return {
        fd = fd,
        userId = nil,
        agent = nil,
        heartCheckTime = nil,
    }
end
GatewayService.ConnectCache = {}
GatewayService.UserCache = {}

GatewayService.Command2Data = function(command)
    return ServiceUtils.DataPack(ServiceUtils.ServiceCommandToClientData(command))
end

-- 拦截器
GatewayService.ExecIntercept = function(idx, command)
    local intercept = this.interceptList[idx]
    if intercept then
        if intercept.ExecBefore and intercept.ExecBefore(command) then
            if not this.interceptList[idx+1] then
                skynet.send(conn.agent, "lua", Instruction.Agent.Internal.CMD_CLIENT, command)
            else
                this.ExecIntercept(idx+1, command)
            end
        end

        if intercept.ExecAfter then
            intercept.ExecAfter(command)
        end
    else
        skynet.send(conn.agent, "lua", Instruction.Agent.Internal.CMD_CLIENT, command)
    end
end

-- 数据返回
GatewayService.internal[Instruction.Gateway.Internal.CMD_SEND_DATA] = function(source, command)
    local user = this.UserCache[command.userId]
    if user then
        this.Log("send fd[" .. user.fd .. "] "..command.data)
        local data = ServiceUtils.ServiceCommandToClientData(command)
        socket.write(user.fd, ServiceUtils.DataPack(data))
    end
end

-- 获取心跳时间
GatewayService.internal[Instruction.Gateway.Internal.CMD_REQUIRE_HEART_CHECK] = function(source, userId)
    return this.UserCache[userId].heartCheckTime
end

-- 接收心跳包
GatewayService.HeartCheck = function(fd)
    local user = this.ConnectCache[fd]
    if user then
        user.heartCheckTime = os.time()
        local command = {
            command = Instruction.CMD_HEART_CHECK,
            data = user.heartCheckTime
        }
        socket.write(fd, this.Command2Data(command))
    end
end

-- 解析分发指令
GatewayService.ProcessMsg = function (fd, data)
    -- 指令解析
    local command = ServiceUtils.DataToServiceCommand(data)

    this.Log("recv fd[" .. fd .. "] user[".. command.userId .."] cmd[" .. command.command .. "] {" .. command.data .. "}")

    local conn = this.ConnectCache[fd]
    local userId = conn.userId

    command.node = this.node
    command.gateway = this.hybrid

    -- 未登录
    if not userId then
        -- 执行自动登录,创建agent,自动绑定
        local nodeCfg = RunConfig[this.node]
        local loginServerId = math.random(1, #nodeCfg.login)
        local loginServerName = "login"..loginServerId
        local hr, agent = skynet.call(loginServerName, "lua", Instruction.Login.Internal.CMD_AUTO_LOGIN, command)
        if not hr then
            this.Log("login failed "..agent)
            return
        end
        conn.userId = command.userId
        conn.token = command.token
        conn.agent = agent
    end

    -- token匹配
    local resp = {
        command = Instruction.CMD_JSON,
        data = nil
    }
    if conn.token ~= command.token then
        resp.data = ServiceUtils.ToJson(ServiceUtils.ErrorResult(Error.NOT_MATCH_LOGIN()))
        socket.write(fd, this.Command2Data(resp))
        return
    end

    -- 不能重复执行登录
    if Instruction.Login.Internal.CMD_AUTO_LOGIN == command.command then
        resp.data = ServiceUtils.ToJson(ServiceUtils.ErrorResult(Error.ALREADY_LOGIN()))
        socket.write(fd, this.Command2Data(resp))
        return
    end

    -- 接收心跳包
    if Instruction.Gateway.CMD_HEART_CHECK == command.command then
        this.HeartCheck(fd)
        return
    end

    -- 执行用户指令
    this.ExecIntercept(1, command)
end

-- 响应buff分割
GatewayService.ProcessBuff = function(fd, readBuff)
    local data = ServiceUtils.DataUnpack(readBuff)
    if not data then
        return readBuff
    end

    while true do
        local msgStr, rest = string.match(readBuff, "(.-)\r\n\r\n(.*)")
        if msgStr then
            s.log(msgStr)
            readBuff = rest
            this.ProcessMsg(fd, msgStr)
        else
            return readBuff
        end
    end
end

-- 断开链接
GatewayService.Disconnect = function (fd)
    local c = this.ConnectCache[fd]
    if not c then
        return
    end

    local userId = c.userId

    if not userId then
        return
    else
        this.UserCache[userId] = nil
        local reason = "断线"
        skynet.call("agentmgr", "lua", "reqkick", userId, reason)
    end
end

-- 接收响应
GatewayService.ReceiveLoop = function(fd)
    socket.start(fd)
    this.Log("socket connected " ..fd)
    local readBuff = ""
    while true do
        local receiveBuff = socket.read(fd)
        if receiveBuff then
            receiveBuff = readBuff .. receiveBuff
            readBuff = this.ProcessBuff(fd, readBuff)
        else
            this.Log("socket close " ..fd)
            this.Disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

-- 连接socket回调
GatewayService.Connect = function(fd, address)
    this.Log("connect from " .. address .. " " .. fd)
    this.ConnectCache[fd] = ConnectCacheItem(fd)
    skynet.fork(this.ReceiveLoop, fd)
end

-- 构造函数
GatewayService.Construct = function()
    this.Log("start")
    local node = skynet.getenv("node")
    local nodeCfg = RunConfig[node]
    local port = nodeCfg.gateway[id].port
    local listenFd = socket.listen("0.0.0.0", port)
    this.Log("Listen socket :", "0.0.0.0", port)
    socket.start(listenFd, this.connect)
end

this.Start(...)
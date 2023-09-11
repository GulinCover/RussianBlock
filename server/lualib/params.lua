function Resp(code, msg, ...)
    return {
        code = code,
        msg = msg,
        data = ...
    }
end

function AutoLoginParams(conn, node, gateway)
    return {
        conn = conn,
        node = node,
        gateway = gateway
    }
end

function GatewayField(fd)
    return {
        fd = fd,
        user_id = nil,
        token = nil,
        agent = nil,
        random_code = nil, -- udp
        chat = nil,
        heart_check_time = nil,
    }
end

function LoginParams(instructs)
    if not instructs or #instructs ~= 3 then
        return nil
    end

    return {
        id = instructs[2],
        token = instructs[3]
    }
end

function PlayerData()
    return {
        id = nil,
        score = nil,
        coords = nil
    }
end

function HeartPacket()
    return {
        id = nil,
        timestamp = nil,
        random = nil
    }
end

function Agent()
    return {
        id = nil,
        agent = nil,
        node = nil
    }
end

function Scene(scene)
    return {
        id = nil,
        scene = scene,
        node = nil
    }
end

return {
    Resp = Resp,
    AutoLoginParams = AutoLoginParams,
    GatewayField = GatewayField,
    LoginParams = LoginParams,
    PlayerData = PlayerData,
    HeartPacket = HeartPacket,
    Agent = Agent,
    Scene = Scene,
}
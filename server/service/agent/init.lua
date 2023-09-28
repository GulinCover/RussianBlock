local skynet = require "skynet"
local s = require "service"
local params = require "params"
local run_config = require "runconfig"
local instruction = require "instruction"

local sys_user_mapper = require "mapper.sys_user"

-- 本局数据
local local_data = {
    score = 0,
}

-- 用户信息
local user_info = {
    user_id = nil,
    scene_id = nil,
    scene = nil,
    match_status = nil,
    rank_num = nil,
    heart_check_time = nil,
    kick_mark = false
}

-- 服务信息
local service_info = {
    gateway = nil,
    node = nil,
    scene_chat = nil,
    room_chat = nil,
}

s.client = {}

-- 发送心跳检测
local heart_check_func = function()
    s.send(nil, service_info.gateway, "send_heart_check", user_info.user_id)
end

-- 心跳包查询
local heart_check_select_func = function()
    local timestamp = s.call(nil, service_info.gateway, "heart_check_select", user_info.user_id)

    if not timestamp then
        return
    end

    if not user_info.heart_check_time then
        user_info.heart_check_time = timestamp
        return
    end

    -- 超时踢出下线
    if timestamp - user_info.heart_check_time > 5000 and not user_info.kick_mark then
        s.log(user_info.id.." 连接超时,下线处理")
        skynet.send("agentmgr", "lua", "reqkick", user_info.user_id)
        return
    end

    user_info.heart_check_time = timestamp
end

-- 发送消息
local send_chat_func = function(message, dests, type, t)
    local chat = service_info[type]
    if not chat and #dests == 1 then
        -- 好友消息
        skynet.send("chatmgr", "lua", "send_message", user_info.user_id, dests[1], message, t)
    end

    -- 其他消息
    for k,v in pairs(dests) do
        skynet.send(chat, "lua", "send_message", user_info.user_id, v, message, t)
    end
end

-- ==================================客户端服务方法=====================================

-- 同步数据
s.client.update = function(source, data)

end

-- 发送信息
s.client.send_chat = function(source, data)
    if not data then
        return
    end

    local type = data.chat_type
    if not type then
        return
    end

    if type == ChatType.FRIEND then
        if data.dest_user_ids and #data.dest_user_ids > 0 then
            send_chat_func(data.message, data.dest_user_ids, 'friend', type)
        end
    elseif type == ChatType.ROOM then
        if data.dest_user_ids and #data.dest_user_ids > 0 then
            send_chat_func(data.message, data.dest_user_ids, 'room_chat', type)
        end
    elseif type == ChatType.SCENE then
        if data.dest_user_ids and #data.dest_user_ids > 0 then
            send_chat_func(data.message, data.dest_user_ids, 'scene_chat', type)
        end
    end
end

-- 接收信息
s.client.send_chat = function(source, s, d, m, t)
    if d == user_info.user_id then
        s.log("receive message "..m.." from "..s.." to "..d)
        m = s.."#"..d.."#"..t.."#"..m
        skynet.send(service_info.gateway, "lua", "send_chat_message", instruction.CMD_CHAT..","..m)
    end
end

-- ==================================服务方法=====================================

-- 标记下线,本局游戏结束后执行下线处理
s.resp.mark_kick = function(source)
    user_info.kick_mark = true
end

-- 加入scene
s.resp.enter_scene = function(source, scene)
    user_info.scene = scene
    user_info.scene_id = scene.id
end

-- 匹配模式
s.resp.match_type = function(source, type)
    if user_info.match_status[1] == 0 then
        user_info.match_status = {type, 0}
        return true
    end
    return false
end

-- 准备就绪
s.resp.ready = function(source, type, ready)
    if user_info.match_status[1] == type then
        user_info.match_status[2] = ready
        return true
    end
    return false
end

-- 参数获取
s.resp.get_properties = function(source, k)
    return user_info[k]
end

-- 用户下线
s.resp.kick = function(source)
    local_data = nil

    -- 踢出chat服务
    if service_info.chat then

    end

    s.log("user kicked")
end

-- 服务退出
s.resp.exit = function(source)
    s.log("service exit")
    local_data = nil
    user_info = nil
    service_info = nil

    -- 删除心跳检测定时任务
    s.send(nil, "nodemgr", "remove_timer_service", s.name..s.id.."heart_send", 200)
    s.send(nil, "nodemgr", "remove_timer_service", s.name..s.id.."heart_select", 200)
    skynet.exit()
end

-- 客户端消息分发
s.resp.client = function(source, cmd, msg)
    if not service_info.gateway then
        service_info.gateway = source
        -- 启动心跳检测定时任务
        s.send(nil, "nodemgr", "new_timer_service", s.name..s.id.."heart_send", 200, heart_check_func)
        s.send(nil, "nodemgr", "new_timer_service", s.name..s.id.."heart_select", 200, heart_check_select_func)
    end
    if s.client[cmd] then
        local ret_msg = s.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", s.id, ret_msg)
        end
    else
        s.log("s.resp.client fail"..cmd)
    end
end

-- 构造函数
s.init = function()
    service_info.node = skynet.getenv('node')
    user_info.heart_check_time = os.time()
    user_info.match_status = {0,0}

    -- 查询数据库获取用户信息
    local ret = skynet.call(sys_user_mapper.selectSysUserById(s.id))
    if not ret or not ret[1] then
        s.log("select user_info exception")
        skynet.send("agentmgr", "lua", "reqkick", s.id)
        return
    end

    user_info.user_id = s.id
    user_info.rank_num = ret[1].rank_num

    -- 查询好友信息,生成好友chat
    ret = skynet.call(sys_user_mapper.selectSysUserFriendById(s.id))
    if not ret or not ret[1] then
        s.log("select user_friend_info exception")
        return
    end
    user_info.friend_list = ret
end

s.start(...)
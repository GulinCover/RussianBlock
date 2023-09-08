local skynet = require "skynet"
local s = require "service"
local run_config = require "runconfig"
local queue = require "skynet.queue"
local params = require "params"

-- 1=��λ,2=ƥ��,3=�Զ���
Type = {
    RANK = 1,
    MATCH = 2,
    CUSTOM = 3,
}

local match_rule = run_config.rank_num_match_rule

local rank_cs = queue()
local match_cs = queue()
local custom_cs = queue()

local room_rank_cache = {}
local room_match_cache = {}
local room_custom_cache = {}

local auto_ready = function(agent, type, ready)
    s.call(agent.node, agent.agent, 'lua', 'ready', type, ready)
end

local set_user_match_mode = function(agent, type)
    s.call(agent.node, agent.agent, 'lua', 'match_type', type)
end

local generate_rank_room = function(agents)
    local flag = false
    for i, v in pairs(agents) do
        local match_status = s.call(v.node, v.agent, 'lua', 'get_properties', 'match_status')
        if match_status[1] ~= Type.RANK or match_status[2] ~= 1 then
            s.log('�û�RANKƥ��ʧ��')
            flag = true
            break
        end
    end

    -- ����ƥ��ʧ���û�
    if flag then
        for i, v in pairs(agents) do
            set_user_match_mode(v.agent, 0)
        end
    end

    -- ����ս��scene
    local scene_id = ''
    for i, v in pairs(agents) do
        scene_id = scene_id .. '$' .. s.call(v.node, v.agent, 'lua', 'get_properties', 'user_id')
    end
    local scene = s.call(node, "nodemgr", "newservice", "scene", "scene", scene_id)

    for i, v in pairs(agents) do
        s.call(v.node, v.agent, 'lua', 'enter_scene', scene)
    end
end

local rank = function(source, agent)
    local rank_num = s.call(agent.node, agent.agent, 'lua', 'get_properties', 'rank_num')
    set_user_match_mode(agent, TYPE.RANK)
    for i, v in ipairs(match_rule) do
        if rank_num >= v[1] and rank_num <= v[2] then
            local r = room_rank_cache[i]
            if not r then
                room_rank_cache[i] = {}
                r = room_rank_cache[i]
            end
            table.insert(r, agent)
            auto_ready(agent, Type.RANK, 1)

            if #r >= 2 then
                -- ƥ�����,���ɷ���
                room_rank_cache[i] = nil
                generate_rank_room(r)
            end
            return
        end
    end

    -- �ǹ�����
    local m = #match_rule + 1
    local r = room_rank_cache[m]
    if not r then
        room_rank_cache[m] = {}
        r = room_rank_cache[m]
    end
    table.insert(r, agent)
    auto_ready(agent, Type.RANK, 1)

    if #r >= 2 then
        -- ƥ�����,���ɷ���
        room_rank_cache[m] = nil
        generate_rank_room(r)
    end
end

local match = function(source, agent)

end

local custom = function(source, agent)

end

s.resp.rank = function(source, agent)
    rank_cs(rank, source, agent)
end

s.resp.match = function(source, agent)
    match_cs(match, source, agent)
end

s.resp.custom = function(source, agent)
    custom_cs(custom, source, agent)
end

s.start(...)
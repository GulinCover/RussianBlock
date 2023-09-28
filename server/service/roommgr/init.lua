local skynet = require "skynet"
local RoomMgrService = require "ServiceAbstract"
local RunConfig = require "RunConfig"
local queue = require "skynet.queue"
local Instruction = require "Instruction"

local this = RoomMgrService

-- 1=排位,2=匹配,3=自定义
Type = {
    RANK = 1,
    MATCH = 2,
    CUSTOM = 3,
}

local MatchRule = RunConfig.rank_num_match_rule

local RankCs = queue()
local MatchCs = queue()
local CustomCs = queue()

local RankRoomItem = function()
    return {
        size = 2,
        agentList = {},
    }
end
this.RoomRankCache = {}
this.RoomMatchCache = {}
this.RoomCustomCache = {}

local generate_rank_room = function(agents)
    local flag = false
    for i, v in pairs(agents) do
        local match_status = s.call(v.node, v.agent, 'lua', 'get_properties', 'match_status')
        if match_status[1] ~= Type.RANK or match_status[2] ~= 1 then
            s.log('用户RANK匹配失败')
            flag = true
            break
        end
    end

    -- 存在匹配失败用户
    if flag then
        for i, v in pairs(agents) do
            set_user_match_mode(v.agent, 0)
        end
    end

    -- 进入战斗scene
    local scene_id = ''
    for i, v in pairs(agents) do
        scene_id = scene_id .. '$' .. s.call(v.node, v.agent, 'lua', 'get_properties', 'user_id')
    end
    local scene = s.call(node, "nodemgr", "newservice", "scene", "scene", scene_id)

    for i, v in pairs(agents) do
        s.call(v.node, v.agent, 'lua', 'enter_scene', scene)
    end
end

local RankCheck = function(room)
    if not room then
        return
    end

    -- 匹配完成
    if #room.agentList == room.size then
        local idx = math.random(1, #room.agentList)
        local node = nil
        local id = os.time()
        for i, v in ipairs(room.agentList) do
            if i == idx then
                node = v.node
            end
            id = '$'..id..v.UserInfo.userId
        end

        if not node then
            node = room.agentList[1].node
        end

        local param = {
            service = 'room',
            name = 'room',
            id = id
        }
        local hr, r = this.Call(node, 'nodemgr', Instruction.NodeMgr.Internal.CMD_NEW_SERVICE, param)
        if not hr then
            this.Log(r)
            return
        end

        local command = {
            type = 1,
            agentList = room.agentList,
        }
        this.Call(node, r, Instruction.Room.Internal.CMD_MATCH_COMPLETE, command)
        room.agentList = {}
    end
end

local Rank = function(command)
    local room = nil

    local rankNum = command.agent.UserInfo.rankNum
    for i, v in ipairs(MatchRule) do
        if rankNum >= v[1] and rankNum <= v[2] then
            room = this.RoomRankCache[v[1]]
            table.insert(room, command.agent)
            break
        end
    end

    -- 非规则内
    if not room then
        room = this.RoomRankCache[MatchRule[#MatchRule][1]]
        table.insert(room, command.agent)
    end

    RankCheck(room)
end

local match = function(source, agent)

end

local custom = function(source, agent)

end

RoomMgrService.internal[Instruction.RoomMgr.Internal.CMD_READY_RANK] = function(source, command)
    RankCs(Rank, command)
end

RoomMgrService.internal[Instruction.RoomMgr.Internal.CMD_READY_MATCH] = function(source, command)
    match_cs(match, command)
end

RoomMgrService.internal.custom = function(source, agent)
    custom_cs(custom, source, agent)
end

-- 构造函数
RoomMgrService.Construct = function()
    for i, v in ipairs(MatchRule) do
        this.RoomRankCache[v[1]] = RankRoomItem()
    end
end

-- 启动函数
this.Start(...)
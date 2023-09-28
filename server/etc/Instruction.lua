return {
    CMD_INTERNAL_TYPE = "internal",
    CMD_RESP_TYPE = "resp",
    CMD_ADD_INTERCEPT = "add_intercept",
    CMD_EXIT = "exit",
    NodeMgr = {
        Internal = {
            CMD_NEW_SERVICE = "new_service"
        },
    },
    Gateway = {
        Internal = {
            CMD_REQUIRE_HEART_CHECK = "require_heart_check",
            CMD_SEND_DATA = "send_data",
        },
        CMD_HEART_CHECK = "heart_check",
    },
    Login = {
        Internal = {
            CMD_AUTO_LOGIN = "auto_login",
        },
        CMD_LOGOUT = "logout",
    },
    AgentMgr = {
        Internal = {
            CMD_REQ_LOGIN = "req_login",
            CMD_KICK_LOGIN = "kick_login",
        },
    },
    Agent = {
        Internal = {
            CMD_CLIENT = "client",
            CMD_SUBSTANTIALIZE_DATA = "substantialize_data",
            CMD_UPDATE_DATA = "update_data",
            CMD_START_GAME = "start_game",
        },
        CMD_READY_MATCH = "ready_match",
        CMD_READY_RANK = "ready_rank",
        CMD_CONFIRM_MATCH = "confirm_match",
        CMD_OPEN_ROOM = "open_room",
        CMD_JOIN_ROOM = "join_room",
        CMD_SEARCH_ROOM = "search_room",
        CMD_CONFIRM_ROOM = "confirm_room",
        CMD_START_ROOM = "start_room",
        CMD_COMPETE_MATCH = "compete_match",
        CMD_START_GAME = "start_game",
        CMD_PAUSE_GAME = "pause_game",
        CMD_VICTORY_GAME = "victory_game",
        CMD_DEFEAT_GAME = "defeat_game",
    },
    RoomMgr = {
        Internal = {
            CMD_READY_MATCH = "ready_match",
            CMD_READY_RANK = "ready_rank",
        },
    },
    Room = {
        Internal = {
            CMD_MATCH_COMPLETE = 'match_complete',
        },
    },
    SceneMgr = {
        Internal = {
            CMD_NEW_SCENE = "new_scene",
        },
    },
    Scene = {
        Internal = {
            CMD_AGENT_SYNC = "agent_sync",
            CMD_DATA_SYNC = "data_sync",
            CMD_START_GAME = "start_game",
        },
    },
    Chat = {
        Internal = {
            CMD_SEND_MESSAGE = "send_message",
        },
    },
    DB = {
        Mysql = {
            Internal = {
                CMD_QUERY = "query",
                CMD_CLOSE = "close",
            },
        },
    },

    CMD_JSON = "json",
    CMD_SERVER_BROADCAST = "broadcast",
}
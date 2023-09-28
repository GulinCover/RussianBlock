function SERVER_EXCEPTION()
    return 500,"服务异常"
end

function OPERATION_SUCCESS()
    return 0,"操作成功"
end

function INSTRUCTION_ERROR()
    return 1,"指令错误"
end

function NOT_LOGIN()
    return 5,"未登录"
end

function NOT_MATCH_LOGIN()
    return 3,"登录参数不匹配"
end

function ALREADY_LOGIN()
    return 4,"已登录"
end

function AGENT_REGISTER_FAIL()
    return 5,"用户代理注册失败"
end

function DATA_EXCEPTION()
    return 6,"数据异常"
end

return {
    CHECK_LOGIN_SUCCESS = "校验登陆成功",
    GATEWAY_REGISTER_FAIL = "网关注册失败",

    SERVER_EXCEPTION = SERVER_EXCEPTION,

    OPERATION_SUCCESS = OPERATION_SUCCESS,

    INSTRUCTION_ERROR = INSTRUCTION_ERROR,
    NOT_LOGIN = NOT_LOGIN,
    NOT_MATCH_LOGIN = NOT_MATCH_LOGIN,
    ALREADY_LOGIN = ALREADY_LOGIN,
    AGENT_REGISTER_FAIL = AGENT_REGISTER_FAIL,
    DATA_EXCEPTION = DATA_EXCEPTION,
}
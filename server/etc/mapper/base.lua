local skynet = require "skynet"

local result_wrapper = function (sql)
    return "mysql", "lua", "query", sql
end

local analysis = function (sql, params)
    for k, v in pairs(params) do
        sql = string.gsub(sql, "#{"..k.."}", "'"..v.."'")
    end
    return sql
end

local sql_wrapper = function (sql, params)
    skynet.error("src sql: "..sql)
    local result = "{"
    for key, value in pairs(params) do
        result = result.. key .. ": " .. value .. ","
    end
    if #result > 1 then
        result = string.sub(result, 1, #result - 1)
    end
    skynet.error("sql params: ".. result.. "}")
    sql = analysis(sql, params)
    skynet.error("sql: ")
    skynet.error("----"..sql)
    skynet.error("result: ")
    return result_wrapper(sql)
end

return {
    sql_wrapper = sql_wrapper,
}
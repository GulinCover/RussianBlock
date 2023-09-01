local skynet = require "skynet"
local runconfig = require "runconfig"
local s = require "service"

local mysql = require "skynet.db.mysql"

s.curr_node = nil;
s.db = nil

local print_ret = function (ret)
    local result = ""
    for i, v in ipairs(ret) do
        for key, value in pairs(v) do
            result = result.. value .. " "
        end
    end
    skynet.error("----".. result)
end

s.init = function ()
    s.curr_node = skynet.getenv("node")
    local db_config = runconfig[s.curr_node].db

    local db = mysql.connect({
        max_idle_timeout = 10000,
        pool_size = 50,
        host = db_config.host,
        port = db_config.port,
        user = db_config.user,
        password = db_config.password,
        database = db_config.database,
        charset = db_config.charset
        })

    if not db then
        skynet.error("mysql connect exception")
    end
    s.db = db

    skynet.error("mysql connect success")
end

s.resp.query = function (source, query)
    local ret = s.db:query(query)

    print_ret(ret)

    if not ret then
        return nil
    end
    return ret
end

s.resp.close = function (source)
    s.db:set_keepalive(10000, 50)
end

s.start(...)
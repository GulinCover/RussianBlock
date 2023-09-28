local skynet = require "skynet"
local RunConfig = require "RunConfig"
local MysqlService = require "ServiceAbstract"
local Instruction = require "Instruction"

local mysql = require "skynet.db.mysql"

local this = MysqlService

this.DB = nil

MysqlService.PrintRet = function (ret)
    local result = ""
    for i, v in ipairs(ret) do
        for key, value in pairs(v) do
            result = result.. value .. " "
        end
    end
    this.Log("----".. result)
end

MysqlService.internal[Instruction.DB.Mysql.Internal.CMD_QUERY] = function (source, query)
    local ret = this.DB:query(query)
    MysqlService.PrintRet(ret)
    return ret
end

MysqlService.internal[Instruction.DB.Mysql.Internal.CMD_CLOSE] = function (source)
    this.DB:set_keepalive(10000, 50)
end

MysqlService.Construct = function ()
    local dbConfig = RunConfig[this.node].db

    local db = mysql.connect({
        max_idle_timeout = 10000,
        pool_size = 50,
        host = dbConfig.host,
        port = dbConfig.port,
        user = dbConfig.user,
        password = dbConfig.password,
        database = dbConfig.database,
        charset = dbConfig.charset
    })

    if not db then
        this.Log("mysql connect exception")
    end
    this.DB = db

    this.Log("mysql connect success")
end

this.Start(...)
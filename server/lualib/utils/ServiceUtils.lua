local cJson = require "cjson"

local service = {
    UUID = function()
        local template ="xxxxxxxxxxxxxxxxxxxx"
        local d = io.open("/dev/urandom", "r"):read(4)
        math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
        return string.upper(string.gsub(template, "x", function (c)
            local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format("%x", v)
        end
        ))
    end,

    DataPack = function(data)
        local uuid = service.UUID()
        return uuid..data.."\r\n\r\n"..uuid
    end,

    DataUnpack = function(data)
        if #data < 40 then
            return nil
        end

        local prefix = string.sub(data, 20)
        local suffix = string.sub(data, -20)
        if prefix ~= suffix then
            return nil
        end

        local src = string.sub(data, 21, #data - 40)
        local separate = string.sub(src, -4)
        if separate ~= "\r\n\r\n" then
            return nil
        end

        return src
    end,

    DataToServiceCommand = function(data)
        local req = {
            command = nil,
            userId = nil,
            token = nil,
            data = nil,
            commandType = nil,
            node = nil,
            hybrid = nil,
        }

        local idx = 0
        while idx < 3 do
            local arg, rest = string.match(data, "(.-),(.*)")

            if arg then
                if idx == 0 then
                    req.command = arg
                elseif idx == 1 then
                    req.userId = arg
                elseif idx == 2 then
                    req.token = arg
                    req.data = rest
                end
            else
                return req
            end

            data = rest
        end

        return req
    end,

    ServiceCommandToClientData = function(command)
        return command.command..","..command.data
    end,

    AjaxResult = function(code, msg, ...)
        return {
            code = code,
            msg = msg,
            data = ...
        }
    end,

    ErrorResult = function(error)
        return {
            code = error[1],
            msg = error[2],
        }
    end,

    ToJson = function(data)
        return cJson.encode(data)
    end,

    FromJson = function(string)
        return cJson.decode(string)
    end,
}

return service
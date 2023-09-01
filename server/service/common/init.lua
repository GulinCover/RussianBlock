
return {
    command = function (msg)
        local idx = 1
        local id = nil
        local token = ""
        local cmd = ""
        local data = {}
        msg = msg .. ","
        while #msg > 0 do
            local m, rest = string.match(msg, "(.-),(.*)")
            if idx == 1 then
                cmd = m
            elseif idx == 2 then
                id = m
            elseif idx == 3 then
                token = m
            else
                data[idx - 3] = m
            end

            idx = idx + 1
            msg = rest
        end

        return {
            cmd = cmd,
            id = id,
            token = token,
            data = data
        }
    end
}
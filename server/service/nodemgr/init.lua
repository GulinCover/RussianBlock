local skynet = require "skynet"
local s = require "service"
local queue = require "service.queue"

local cs = queue()
local service_timer_cache = {}

-- ��ʱ�������
local timer_queue_func = function(time)
    while true do
        for k,v in pairs(service_timer_cache) do
            if k == time then
                for name,func in pairs(v) do
                    cs(func)
                end
            end
        end

        skynet.sleep(time * 0.1)
    end
end

-- ��Ӷ�ʱ����
local new_timer_service_func = function(name, time, func)
    local timer = service_timer_cache[time]
    if timer then
        local target = timer[name]
        if target then
            s.log("replace timer service " ..name.."["..time.."]")
        else
            s.log("startup timer service " ..name.."["..time.."]")
        end
        timer[name] = func
    else
        s.log("startup timer service " ..name.."["..time.."]")
        service_timer_cache[time] = {
            [name] = func
        }
        skynet.fork(timer_queue_func, time)
    end
end

-- �Ƴ���ʱ����
local remove_timer_service_func = function(name, time)
    local timer = service_timer_cache[time]
    if timer then
        local target = timer[name]
        if target then
            s.log("remove timer service " ..name.."["..time.."]")
            timer[name] = nil
        else
            s.log("remove timer service not found" ..name.."["..time.."]")
        end

        if #timer == 0 then
            service_timer_cache[time] = nil
        end
    else
        s.log("remove timer service not found" ..name.."["..time.."]")
    end
end

-- =============================== ������ ===================================

-- ��������
s.resp.newservice = function (source, name, ...)
    s.log("startup service " ..name.. ...)
    local srv = skynet.newservice(name, ...)
    return srv
end

-- ��Ӷ�ʱ����
s.resp.new_timer_service = function (source, name, time, func)
    cs(new_timer_service_func, name, time, func)
end

-- �Ƴ���ʱ����
s.resp.remove_timer_service = function (source, name, time)
    cs(remove_timer_service_func, name, time)
end

s.start(...)
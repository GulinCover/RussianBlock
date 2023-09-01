local base = require "mapper.base"

local m = {
    selectSysUserById = "SELECT id,login_name,password,token FROM sys_user WHERE id = #{id}",
    selectSysUserByTokenId = "SELECT id,login_name,password,token FROM sys_user WHERE id = #{id} AND token = #{token}",
}

return {
    selectSysUserById = function (id)
        return base.sql_wrapper(m.selectSysUserById, {id=id})
    end,

    selectSysUserByTokenId = function (id, token)
        return base.sql_wrapper(m.selectSysUserByTokenId, {id=id, token=token})
    end
}
local BaseMapper = require "mapper.BaseMapper"

local m = {
    selectSysUserById = "
    SELECT
        id,login_name,password,token,rank_num
    FROM sys_user
    WHERE id = #{id}
    ",
    selectSysUserByTokenId = "
    SELECT
        id,login_name,password,token,rank_num
    FROM sys_user
    WHERE id = #{id} AND token = #{token}
    ",
}

return {
    selectSysUserById = function (id)
        return BaseMapper.SqlWrapper(m.selectSysUserById, {id=id})
    end,

    selectSysUserByTokenId = function (id, token)
        return BaseMapper.SqlWrapper(m.selectSysUserByTokenId, {id=id, token=token})
    end,

    selectSysUserFriendById = function (id, token)
        return BaseMapper.SqlWrapper(m.selectSysUserByTokenId, {id=id, token=token})
    end,
}
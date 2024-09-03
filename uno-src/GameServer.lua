local skynet = require "skynet"
require "gas.playerMgr"
require "gas.rpcMgr"
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		local uid, msg = skynet.unpack(msg, sz)
		local player = PlayerMgr:GetById(uid)
		if not player then
			skynet.error(string.format("player %s is not exist", uid))
			return
		end
		return player, msg 
	end,
}

SOURCE_GATE = nil
CmdMgr = {}

function CmdMgr.login(source, uid, sid, username, secret)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	if not SOURCE_GATE then
		SOURCE_GATE = source
	elseif SOURCE_GATE ~= source then
		skynet.error("SOURCE_GATE is conflict")
		return
	end

	PlayerMgr:Add(uid, sid, username)
	-- you may load user data from database
end

-- 玩家离线暂不处理
function CmdMgr.logout(source, userid)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	local player = PlayerMgr:GetById(userid)
	if player and SOURCE_GATE then
		skynet.call(SOURCE_GATE, "lua", "logout", userid, player.m_Sid)
	end
	PlayerMgr:Logout(userid)
end

function CmdMgr.afk(source, userid)
	-- the connection is broken, but the user may back
	skynet.error(string.format("AFK %s", userid))

	-- 玩家离线 隔一段时间后踢出 TODO
end

skynet.start(function()
	-- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CmdMgr[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", RpcMgr._RecvMsg)
end)

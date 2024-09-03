MSG_SERVER = require "snax.msgserver"
local crypt = require "skynet.crypt"
local skynet = require "skynet"

LOGIN_SERVICE = tonumber(...)
SERVER_NAME = "default"
INTERNAL_ID = 0
SERVER_CALLBACK = {}

USERS = {}
USERNAME_MAP = {}	-- username实际上是一个token，详见msgserver.username

GameServer = nil
-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function SERVER_CALLBACK.login_handler(uid, secret)
	if USERS[uid] then
		error(string.format("%s is already login", uid))
	end

	INTERNAL_ID = INTERNAL_ID + 1
	local id = INTERNAL_ID	-- don't use INTERNAL_ID directly
	local username = MSG_SERVER.username(uid, id, SERVER_NAME)

	-- you can use a pool to alloc new agent
	local u = {
		username = username,
		uid = uid,
		subid = id,
	}

	-- trash subid (no used)
	GameServer = skynet.uniqueservice "GameServer"
	skynet.call(GameServer, "lua", "login", uid, id, username, secret)

	USERS[uid] = u
	USERNAME_MAP[username] = u

	MSG_SERVER.login(username, secret)

	-- you should return unique subid
	return id
end

-- call by gameServer
function SERVER_CALLBACK.logout_handler(uid, subid)
	local u = USERS[uid]
	if u then
		local username = MSG_SERVER.username(uid, subid, SERVER_NAME)
		assert(u.username == username)
		MSG_SERVER.logout(u.username)
		USERS[uid] = nil
		USERNAME_MAP[u.username] = nil
		skynet.call(LOGIN_SERVICE, "lua", "logout",uid, subid)
	end
end

-- call by login server
function SERVER_CALLBACK.kick_handler(uid, subid)
	local u = USERS[uid]
	if u then
		local username = MSG_SERVER.username(uid, subid, SERVER_NAME)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, GameServer, "lua", "logout", uid, subid)
	end
end

-- call by self (when socket disconnect)
function SERVER_CALLBACK.disconnect_handler(username)
	local u = USERNAME_MAP[username]
	if u then
		skynet.call(GameServer, "lua", "afk", u.uid, u.subid)
	end
end

-- call by self (when recv a request from client)
function SERVER_CALLBACK.request_handler(username, msg)
	local u = USERNAME_MAP[username]
	return skynet.tostring(skynet.rawcall(GameServer, "client", skynet.pack(u.uid, msg)))
end

-- call by self (when gate open)
function SERVER_CALLBACK.register_handler(name)
	SERVER_NAME = name
	skynet.call(LOGIN_SERVICE, "lua", "register_gate", SERVER_NAME, skynet.self())
end

MSG_SERVER.start(SERVER_CALLBACK)


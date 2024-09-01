local skynet = require "skynet"

skynet.start(function()
	local loginserver = skynet.uniqueservice("logind")
	local gate = skynet.uniqueservice("gated", loginserver)

	skynet.call(gate, "lua", "open" , {
		port = 8888,
		maxclient = 64,
		servername = "sample",
	})
end)

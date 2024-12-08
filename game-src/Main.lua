skynet = require "skynet"
skynet.start(function()
	skynet.uniqueservice("DatabaseMgr")
	skynet.uniqueservice("ConnMgr","0.0.0.0:8776")
	skynet.uniqueservice("RpcMgr")
	skynet.uniqueservice("ConsoleMgr")
	skynet.uniqueservice("AccountMgr")
	skynet.uniqueservice("PlayerMgr")
	skynet.uniqueservice("debug_console", 8000)
end)
skynet = require "skynet"
skynet.start(function()
	skynet.uniqueservice("DatabaseMgr")
	skynet.uniqueservice("ConnMgr","0.0.0.0:8776")
	skynet.uniqueservice("ConsoleMgr")
	skynet.uniqueservice("AccountMgr")
	skynet.uniqueservice("debug_console", 8000)
end)

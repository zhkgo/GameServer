local skynet = require "skynet"
skynet.start(function()
	skynet.uniqueservice("DatabaseMgr")
	skynet.uniqueservice("ConnMgr","0.0.0.0:8776")
	skynet.uniqueservice("ConsoleMgr")
	skynet.uniqueservice("AccountMgr")
end)

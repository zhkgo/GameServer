local skynet = require "skynet"
skynet.start(function()
	skynet.uniqueservice("ConnMgr","0.0.0.0:8776")
	skynet.uniqueservice("DatabaseMgr")
	skynet.uniqueservice("ConsoleMgr")
end)

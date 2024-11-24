local skynet = require "skynet"
skynet.start(function()
	skynet.uniqueservice("GateWay","0.0.0.0:8776")
	skynet.uniqueservice("DatabaseMgr")
end)

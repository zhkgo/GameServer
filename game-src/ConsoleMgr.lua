skynet = require "skynet"
snax   = require "skynet.snax"
socket = require "skynet.socket"

require "common.Utils"

function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

function console_main_loop()
	local stdin = socket.stdin()
	while true do
		local cmdline = socket.readline(stdin, "\n")
		local split = split_cmdline(cmdline)
		local command = split[1]
		if command == "snax" then
			pcall(snax.newservice, select(2, table.unpack(split)))
		elseif command == "lua" then
			-- 运行代码
			local code = string.sub(cmdline, 5)
			local func, err = load(code)
			if func then
				PrintTable(func())
			else
				print(err)
			end
		elseif cmdline ~= "" then
			pcall(skynet.newservice, cmdline)
		end
	end
end

skynet.start(function()
	skynet.fork(console_main_loop)
end)

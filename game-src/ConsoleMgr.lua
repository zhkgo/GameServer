local skynet = require "skynet"
local snax   = require "skynet.snax"
local socket = require "skynet.socket"

function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end


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
				print(dump(func()))
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

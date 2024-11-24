local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local CreateTableList, StatementTable = require "commondef.SQLTableDefine"

DatabaseMgr = {}
CMD = {}

-- 打印table
local function dump(obj)
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

-- 初始化模块
function DatabaseMgr:InitModule()
	-- 连接数据库
	if not self:DoConnect() then
		return
	end

	-- 创建不存在的表
	self:PrepareTableNotExists()

	-- 预备statement
	self:PrepareStatement()

	-- 等待其他服务调用
    skynet.dispatch("lua", function(_, source, cmd, ...)
        self:SendDataToAddr(_, source, cmd, ...)
    end)
end

-- 连接数据库
function DatabaseMgr:DoConnect()
	local function on_connect(db)
		db:query("set charset utf8mb4");
	end
	self.m_db = mysql.connect({
		host="127.0.0.1",
		port=3309,
		database="skynet",
		user="root",
		password="123456",
                charset="utf8mb4",
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})

	if not self.m_db then
		print("failed to connect")
		return
	end
	print("success to connect to mysql server")
end

-- 创建不存在的表, 如果要调整表结构, 就需要去数据库重新操作并修改表结构
function DatabaseMgr:PrepareTableNotExists()
	for _, v in ipairs(CreateTableList) do
		local res = self.m_db:query(v[1])
		print(dump(res))
	end
end

-- 预备statement
function DatabaseMgr:PrepareStatement()
	-- PlayData 针对某个key的数据字段，存入一个info，info可能很长，所以需要多个info，用idx区分顺序
	-- 需要保证写入流程，先delete后insert，可能会导致数据丢失，暂时没想到好办法。
	DatabaseMgr.m_StateMents = {}
	for k, v in pairs(StatementTable) do
		DatabaseMgr.m_StateMents[k] = {}
		for k1, v1 in pairs(v) do
			DatabaseMgr.m_StateMents[k.."_"..k1] = self.m_db:prepare(v1)
		end
	end
end

-- 收到lua类型消息 进行相应处理
function DatabaseMgr:SendDataToAddr(_, source, cmd, ...)
    local f = assert(CMD[cmd])
    f(source, ...)
end

function CMD.SavePlayData(source, key, info)
    -- 删除旧数据
    self.m_db:execute(DatabaseMgr.m_StateMents["PlayData_DeleteKey"], key)
    -- 插入新数据 需要拆分每个8192
    for i = 1, #info, 8192 do
        local res = self.m_db:execute(DatabaseMgr.m_StateMents["PlayData_Insert"], key, info:sub(i, i + 8192), i)
    end
    skynet.ret()
end

function CMD.LoadPlayData(source, key)
    local res = self.m_db:query(DatabaseMgr.m_StateMents["PlayData_SelectKey"], key)
    skynet.ret(res)
end

skynet.start(function()
	DatabaseMgr:InitModule()
end)


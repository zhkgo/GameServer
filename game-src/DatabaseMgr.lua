skynet = require "skynet.manager"
mysql = require "skynet.db.mysql"
SQLTableDefine = require "defs.SQLTableDefine"
CreateTableList, StatementTable = table.unpack(SQLTableDefine)

DatabaseMgr = {}

-- 初始化模块
function DatabaseMgr:InitModule()
    -- 加载依赖模块
    require "common.Utils"

	-- 连接数据库
	if not self:DoConnect() then
		return
	end

	-- 创建不存在的表
	self:PrepareTableNotExists()

	-- 预备statement
	self:PrepareStatement()
 
	-- 等待其他服务调用
    skynet.dispatch("lua", DealLuaMessage)

	-- 具名服务
	skynet.register(".DatabaseMgr")
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
    return true
end

-- 创建不存在的表, 如果要调整表结构, 就需要手动去数据库重新操作并修改表结构
function DatabaseMgr:PrepareTableNotExists()
	for _, v in ipairs(CreateTableList) do
		self.m_db:query(v)
	end
end

-- 预备statement
function DatabaseMgr:PrepareStatement()
	DatabaseMgr.m_StateMents = {}
	for k, v in pairs(StatementTable) do
		for k1, v1 in pairs(v) do
			DatabaseMgr.m_StateMents[k.."_"..k1] = self.m_db:prepare(v1)
		end
	end
end

-- 收到lua类型消息 进行相应处理
function DealLuaMessage(_, source, cmd, ...)
    local f = assert(DatabaseMgr.m_StateMents[cmd])
    local res = DatabaseMgr.m_db:execute(f, ...)
    if res.badresult then
        skynet.error("bad result")
        PrintTable(res)
    end

    skynet.retpack(res)
end

skynet.start(function()
	DatabaseMgr:InitModule()
end)


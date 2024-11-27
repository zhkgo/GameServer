local skynet = require "skynet"

local DatabaseAddr = skynet.queryservice("DatabaseMgr")

PlayDataHelper = {}

function PlayDataHelper.SavePlayData(PlayName, PlayData)
    -- 计算需要几个subkey
    local slice = 40000
    local n = math.ceil(#PlayData / slice)
    for i = 1, n do
        local SubData = string.sub(PlayData, (i - 1) * slice + 1, i * slice)
        skynet.call(DatabaseAddr, "lua", "PlayData_Insert", PlayName, i, SubData)
    end
    skynet.call(DatabaseAddr, "lua", "PlayData_Insert", PlayName, n+1, "")
end

function PlayDataHelper.LoadPlayData(PlayName)
    local PlayData = {}
    local i = 1
    local endFlag = false
    local res = skynet.call(DatabaseAddr, "lua", "PlayData_SelectKey", PlayName)

    -- 若没有数据则返回
    if #res == 0 then
        return
    end

    -- 按需加载数据
    for _, v in ipairs(res) do
        -- 若数据存在则加载
        if not endFlag and v['SubKey'] == i then
            table.insert(PlayData, v['Info'])
            i = i + 1
        end
        -- 若已经到最后一个数据则其他数据应当删除
        if endFlag then
            skynet.call(DatabaseAddr, "lua", "PlayData_DeleteKey", PlayName, v['SubKey'])
        end
        -- 最后一个有效数据
        if v['Info'] == "" then
            endFlag = true
        end
    end
    return table.concat(PlayData)
end

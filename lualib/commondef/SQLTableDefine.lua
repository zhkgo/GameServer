local createList = {
    [[
        CREATE TABLE IF NOT EXISTS `PlayData` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,            -- 自增主键，唯一标识每一行
            `key` VARCHAR(100) COLLATE utf8mb4_bin,         -- key,允许重复值
            `info` VARCHAR(8192) COLLATE utf8mb4_bin DEFAULT NULL,   -- 数据字段
            `idx` INT DEFAULT 0                             -- 一个key对应多个info时, 用idx区分
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
	]]
}

local statementTable = {
    ['PlayData'] = {
        -- 插入数据
        Insert = [[
            INSERT INTO `PlayData` (`key`, `info`, `idx`) VALUES (?, ?, ?);
        ]],
        -- 查询key的数据
        SelectKey = [[
            SELECT `info` FROM `PlayData` WHERE `key` = ?;
        ]],
        -- 删除key对应的所有数据
        DeleteKey = [[
            DELETE FROM `PlayData` WHERE `key` = ?;
        ]],
    }
}

return createList, statementTable
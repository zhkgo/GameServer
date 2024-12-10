local createList = {
    [[
        CREATE TABLE IF NOT EXISTS `PlayData` (
            `PlayName` VARCHAR(100) COLLATE utf8mb4_bin NOT NULL,
            `SubKey` INT NOT NULL,
            `Info` VARBINARY(40960) DEFAULT NULL,
            PRIMARY KEY (`PlayName`, `SubKey`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
	]]
    ,
    -- 用户账号密码表
    [[
        CREATE TABLE IF NOT EXISTS `Account` (
            `UserId` INT NOT NULL,
            `UserName` VARCHAR(20) COLLATE utf8mb4_bin NOT NULL,
            `Password` VARCHAR(33) COLLATE utf8mb4_bin NOT NULL,
            PRIMARY KEY (`UserId`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
    ]]
}

local statementTable = {
    ['PlayData'] = {
        -- 插入数据，如果已经存在则替换
        Insert = [[
            INSERT INTO `PlayData` (`PlayName`, `SubKey`, `Info`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `Info` = VALUES(`Info`);
        ]],
        -- 查询PlayName的数据并按SubKey排序
        SelectKey = [[
            SELECT `SubKey`,`Info` FROM `PlayData` WHERE `PlayName` = ? ORDER BY `SubKey`;
        ]],
        -- 删除指定主键的数据
        DeleteKey = [[
            DELETE FROM `PlayData` WHERE `PlayName` = ? AND `SubKey` = ?;
        ]],
    },
    ['Account'] = {
        -- 插入数据，如果已经存在则替换
        Insert = [[
            INSERT INTO `Account` (`UserId`, `UserName`, `Password`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `UserName` = VALUES(`UserName`), `Password` = VALUES(`Password`);
        ]],
        -- 查询用户账号密码
        Select = [[
            SELECT `UserName`, `Password` FROM `Account` WHERE `UserId` = ?;
        ]],
        -- 删除指定主键的数据
        Delete = [[
            DELETE FROM `Account` WHERE `UserId` = ?;
        ]],
        SelectAll = [[
            SELECT `UserId`, `UserName`, `Password` FROM `Account`;
        ]],
    }
}
return {createList, statementTable}
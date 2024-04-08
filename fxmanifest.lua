fx_version 'cerulean'
games { 'gta5' }
version '0.1a'
lua54 'yes'
author 'BLUGTHEK'
description 'UtilExtended'

client_scripts { -- สำหรับส่วนผู้ใช้ และ การแสดงผลให้ผู้ใช้ รวมถึงส่วนติดต่อ UI
    'client/client.lua',
}

shared_scripts { -- ใช้ได้ทั้ง client และ server หากมีเก็บ Logic ไว้ไม่แนะนำให้แชร์
    '@ox_lib/init.lua',
    'init.lua',
    'config/config.lua',
}

server_scripts { -- เก็บ Logic ที่ต้องคิดบน Server เท่านั้น
    '@mysql-async/lib/MySQL.lua', -- เวลาเรียกใช้ SQL
    'server/server.lua',
}

files {
    'module/**/client.lua',
    'module/**/shared.lua',
}

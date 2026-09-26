fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Custom'
description 'Wedding Ring Item - Pakai/Lepas + Ukir Nama Pasangan'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}
client_script 'client.lua'
server_script 'server.lua'



data_file 'DLC_ITYP_REQUEST' 'stream/weddingring.ytyp'

dependency 'ox_inventory'

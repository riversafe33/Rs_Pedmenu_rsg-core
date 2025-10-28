fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'riversafe'
description 'Peds Menu'
version '1.0.0'

shared_scripts {
    'config.lua',
}

server_scripts {
	'config.lua',
	'server.lua',
}

client_scripts {
	'config.lua',
	'client.lua',
	'clientadmin.lua',
}
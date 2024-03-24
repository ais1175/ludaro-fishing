fx_version("cerulean")
game("gta5")
lua54("yes")
name("Ludaro-Fishing")
author("Ludaro // Isi")
description("A Simple Fishing Script")
version("1")

client_scripts({
	"client/*.lua",
})

server_scripts({
	"server/*.lua",
})

shared_scripts({
	"@ox_lib/init.lua",
	"config/*.lua",
})

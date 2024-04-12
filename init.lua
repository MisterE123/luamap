-- first, set up the non-async api
dofile(minetest.get_modpath("luamap") .. "/common_api.lua")
dofile(minetest.get_modpath("luamap") .. "/regular_api.lua")



-- check if the async environment is available, if so, set it up
if minetest.register_mapgen_script then
	minetest.register_mapgen_script(minetest.get_modpath("luamap") .. "/common_api.lua")
	minetest.register_mapgen_script(minetest.get_modpath("luamap") .. "/async_api.lua")
end

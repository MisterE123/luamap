LUAMAP_IS_REGULAR_MAPGEN_ENV = true
local api = minetest.get_modpath("luamap").."/api.lua"
dofile(api)
pcall(minetest.register_mapgen_dofile(api))
-- Set mapgen parameters
function luamap.set_singlenode()
    minetest.register_on_mapgen_init(function(mgparams)
        minetest.set_mapgen_params({mgname="singlenode"})
    end)
end

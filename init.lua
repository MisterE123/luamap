-- functions that are common to both the main env and the async
dofile(core.get_modpath("luamap").."/common.lua")

-- Set mapgen parameters
function luamap.set_singlenode()
    core.register_on_mapgen_init(function(mgparams)
        core.set_mapgen_params({mgname="singlenode"})
    end)
end


core.register_on_generated(function(minp, maxp, seed)
	local vm, emin, emax = core.get_mapgen_object("voxelmanip")
	local data = luamap.on_generated(vm, emin, emax, minp, maxp, seed)
	vm:write_to_map(data)
end)


local use_async = core.settings:get_bool("luamap_use_async", true)


-- register async mapgen
if use_async == true then
	core.register_mapgen_script(core.get_modpath("luamap").."/async.lua")
end

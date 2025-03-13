-- initializing the async mapgen environment

dofile(core.get_modpath("luamap").."/common.lua")

core.register_on_generated(function(vm, minp, maxp, blockseed)
    local emin, emax = vm:get_emerged_area()
    luamap.on_generated(vm, emin, emax, minp, maxp, blockseed)
    -- no need to write to map here
end)
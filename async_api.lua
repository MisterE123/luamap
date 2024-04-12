-- this file contains functions specific to the async api

local mapgen = luamap.mapgen

minetest.register_on_generated(function(vm, minp, maxp, seed)
    local emin, emax = vm:get_emerged_area()
    mapgen(vm,minp,maxp,emin,emax,seed,true)
end)
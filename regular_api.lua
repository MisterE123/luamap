-- this file contains functions for the regular (non-async) mapgen enviromnent

-- Set mapgen parameters
function luamap.set_singlenode()
    minetest.register_on_mapgen_init(function(mgparams)
        minetest.set_mapgen_params({mgname="singlenode"})
    end)
end




local mapgen = luamap.mapgen
minetest.register_on_generated(function(minp, maxp, seed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    mapgen(vm,minp,maxp,emin,emax,seed,false)
end)
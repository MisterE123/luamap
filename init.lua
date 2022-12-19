luamap = {}
luamap.noises = {}

function luamap.remap(val, min_val, max_val, min_map, max_map)
	return (val-min_val)/(max_val-min_val) * (max_map-min_map) + min_map
end

function luamap.lerp(var_a, var_b, ratio)
	return (1-ratio)*var_a + (ratio*var_b)
end

function luamap.register_noise(name,data)
    luamap.noises[name] = {}
    luamap.noises[name].np_vals = data.np_vals
    luamap.noises[name].nobj = nil
    luamap.noises[name].type = data.type or "2d"
end

local c_air = minetest.get_content_id("air")

-- override this function
function luamap.logic(noise_vals,x,y,z,seed)
    return c_air
end

-- override this function
function luamap.precalc(data, area, vm, minp, maxp, seed)
    return
end


-- Set mapgen parameters
function luamap.set_singlenode()
    minetest.register_on_mapgen_init(function(mgparams)
        minetest.set_mapgen_params({mgname="singlenode"})
    end)
end

minetest.register_on_generated(function(minp, maxp, seed)
	-- local t0 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	


	local sidelen = x1 - x0 + 1
	local ystridevm = sidelen + 32
	--local zstridevm = ystride ^ 2
    
	local chulens3d = {x=sidelen, y=sidelen+17, z=sidelen}
	local chulens2d = {x=sidelen, y=sidelen, z=1}
	local minpos3d = {x=x0, y=y0-16, z=z0}
	local minpos2d = {x=x0, y=z0}
	
    for name,elements in pairs(luamap.noises) do
        if luamap.noises[name].type == "2d" then
            luamap.noises[name].nobj = luamap.noises[name].nobj or minetest.get_perlin_map(luamap.noises[name].np_vals, chulens2d)
            luamap.noises[name].nvals = luamap.noises[name].nobj:get2dMap_flat(minpos2d)
        else -- 3d
            luamap.noises[name].nobj = luamap.noises[name].nobj or minetest.get_perlin_map(luamap.noises[name].np_vals, chulens3d)
            luamap.noises[name].nvals = luamap.noises[name].nobj:get3dMap_flat(minpos3d)
        end
    end
       


	local ni3d = 1
	local ni2d = 1

	for z = z0, z1 do

		for y = y0 - 16, y1 + 1 do
			local vi = area:index(x0, y, z)
			for x = x0, x1 do
				
                local noise_vals = {}
                for name,elements in pairs(luamap.noises) do
                    if elements.type == "2d" then
                        noise_vals[name] = elements.nvals[ni2d]
                    else -- 3d
                        noise_vals[name] = elements.nvals[ni3d]
                    end
                end

                data[vi] = luamap.logic(noise_vals,x,y,z,seed)

				ni3d = ni3d + 1
				ni2d = ni2d + 1
				vi = vi + 1
			end
			ni2d = ni2d - sidelen
		end
		ni2d = ni2d + sidelen
	end
	luamap.precalc(data, area, vm, minp, maxp, seed)
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
end)
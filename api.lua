local is_reg_env = false
if LUAMAP_IS_REGULAR_MAPGEN_ENV then
    is_reg_env = true
end

luamap = {}
luamap.noises_2d = {}
luamap.noises_3d = {}

local worldseed = minetest.get_mapgen_setting("seed")

-- get_perlin_map is not available in async
local noisemap
if is_reg_env then
    noisemap = function(np,size)
        return minetest.get_perlin_map(np,size)
    end
else
    noisemap = function(np,size)
        np.seed = ( np.seed or 0 ) + worldseed
        return PerlinNoiseMap(np,size)
    end
end


function luamap.remap(val, min_val, max_val, min_map, max_map)
	return (val-min_val)/(max_val-min_val) * (max_map-min_map) + min_map
end

-- linear interpolation, optional power modifier
function luamap.lerp(var_a, var_b, ratio, power)
	if ratio > 1 then ratio = 1 end
	if ratio < 0 then ratio = 0 end
	power = power or 1
	return (1-ratio)*(var_a^power) + (ratio*(var_b^power))
end

function luamap.coserp(var_a,var_b,ratio)
	if ratio > 1 then ratio = 1 end
	if ratio < 0 then ratio = 0 end
	local rat2 = (1-math.cos(ratio*3.14159))/2
	return (var_a*(1-rat2)+var_b*rat2)
end

function luamap.register_noise(name,data)
	if data.type == "2d" then
		luamap.noises_2d[name] = {}
		luamap.noises_2d[name].np_vals = data.np_vals
		luamap.noises_2d[name].nobj = nil
		luamap.noises_2d[name].ymin = data.ymin or -31000
		luamap.noises_2d[name].ymax = data.ymax or 31000
	else -- 3d
		luamap.noises_3d[name] = {}
		luamap.noises_3d[name].np_vals = data.np_vals
		luamap.noises_3d[name].nobj = nil
		luamap.noises_3d[name].ymin = data.ymin or -31000
		luamap.noises_3d[name].ymax = data.ymax or 31000
	end
end

local c_air = minetest.get_content_id("air")

-- override this function
function luamap.logic(noise_vals,x,y,z,seed,original_content)
    return original_content or c_air
end

-- override this function
function luamap.precalc(data, area, vm, minp, maxp, seed)
    return
end

-- override this function
function luamap.postcalc(data, area, vm, minp, maxp, seed)
    return
end



local noise_vals = {}

local function mapgen(vm,minp,maxp,emin,emax,seed)

	-- localize vars 
	local logic = luamap.logic
	local noises_2d = luamap.noises_2d
	local noises_3d = luamap.noises_3d

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	
	local data = vm:get_data()
	local sidelen = maxp.x - minp.x + 1
	local chulens3d = {x=sidelen, y=sidelen, z=sidelen}
	local chulens2d = {x=sidelen, y=sidelen, z=1}
	
	local minpos3d = {x=minp.x, y=minp.y-16, z=minp.z}
	local minpos2d = {x=minp.x, y=minp.z}
	
	luamap.precalc(data, area, vm, minp, maxp, seed)

    for name,elements in pairs(noises_2d) do
		if not(maxp.y <= elements.ymin and minp.y >= elements.ymax) then
			noises_2d[name].nobj = noises_2d[name].nobj or noisemap(noises_2d[name].np_vals, chulens2d)
			noises_2d[name].nvals = noises_2d[name].nobj:get_2d_map_flat(minpos2d)
			noises_2d[name].use = true
		else
			noises_2d[name].use = false
		end
    end

	for name,elements in pairs(noises_3d) do
		if not(maxp.y <= elements.ymin and minp.y >= elements.ymax) then
			noises_3d[name].nobj = noises_3d[name].nobj or noisemap(noises_3d[name].np_vals, chulens3d)
			noises_3d[name].nvals = noises_3d[name].nobj:get_3d_map_flat(minpos3d)
			noises_3d[name].use = true
		else
			noises_3d[name].use = false
		end
    end

	local xstride, ystride, zstride = 1,sidelen,sidelen*sidelen


	local i2d = 1
	local i3dz = 1

	for z = minp.z, maxp.z do
		local i3dx=i3dz

		for x = minp.x, maxp.x do
			
			for name,elements in pairs(noises_2d) do
				if elements.use then
					noise_vals[name] = elements.nvals[i2d]
				end
			end

			local i3dy=i3dx
			for y = minp.y, maxp.y do
				local vi = area:index(x, y, z)
                for name,elements in pairs(noises_3d) do
					if elements.use then
                    	noise_vals[name] = elements.nvals[i3dy]
					end
                end
                data[vi] = logic(noise_vals,x,y,z,seed,data[vi])
				i3dy = i3dy + ystride 
			end
			
			i3dx = i3dx + xstride
			i2d = i2d + 1
		end
		i3dz=i3dz+zstride
	end
	luamap.postcalc(data, area, vm, minp, maxp, seed)
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map(data)
	vm:update_liquids()
end

-- the different environments are a bit different in their setup:
if is_reg_env then
    minetest.register_on_generated(function(minp, maxp, seed)
        local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
        mapgen(vm,minp,maxp,emin,emax,seed)
    end)
else
    minetest.register_on_generated(function(vm, seed)
        local emin, emax = vm:get_emerged_area()
        local minp = vector.add(emin, 16)
        local maxp = vector.subtract(emax, 1)
        mapgen(vm,minp,maxp,emin,emax,seed)
    end)
end
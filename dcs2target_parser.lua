-- CONFIGURATION

local dcs_folder = arg[1]..'/'

local modules = {
	'Mods/aircraft/A-10C/Input/',
	'Mods/aircraft/Bf-109K-4/Input/',
	'Mods/aircraft/F-86/Input/',
	'Mods/aircraft/FW-190D9/Input/',
	'Mods/aircraft/Ka-50/Input/',
	'Mods/aircraft/Mi-8MTV2/Input/',
	'Mods/aircraft/P-51D/Input/',
	'Mods/aircraft/Su-25T/Input/',
	'Mods/aircraft/TF-51D/Input/',
	'Mods/aircraft/Uh-1H/Input/',
	'Mods/aircraft/Flaming Cliffs/Input/',
	'Mods/tech/CombinedArms/',
}

-- MODULES
local gettext = require('i_18n')
local lfs = require('lfs')
gettext.set_package("input")
gettext.set_locale_dir('l10n')
gettext.init()

-- VARIABLES
local planes = {}
local EMPTY = '"EMPTY"'

-- GLOBAL FUNCTIONS FOR THE MAPPERS
function _(name)
	return name
end

function defaultDeviceAssignmentFor(str)
	return nil
end

dofile_old = dofile
function dofile(f)
	return dofile_old(dcs_folder..f)
end
external_profile = dofile

function join(to, from)
	for i, value in ipairs(from) do
		table.insert(to, value)
	end

	return to
end

-- LOCAL HELPER FUNCTIONS
local function translate(str)
	local result = str
	if str then
		result = gettext.translate(str)
	end
	return result
end

local function getVariants()
	local variants = {}
	for i, mod in pairs(modules or {}) do
		for variant in lfs.dir(dcs_folder..mod) do
			if variant ~= "." and
				variant ~= ".." and
				variant ~= ".svn"
			then
				local attr = lfs.attributes (dcs_folder..mod..variant)
				if attr.mode == "directory" then
					local name = io.open(dcs_folder..mod..variant..'/'..'name.lua')
					if name then
						variants[variant] = mod..variant
						io.close(name)
						print(variant)
					end
				end
			end
		end
	end
	return variants
end

function load_layout(name, dir, luamap)
	-- this is a global variable DCS sets for profiles
	folder = dir
	local f = loadfile(dcs_folder..dir..luamap)
	if f == nil then
		return
	end
	planes[name] = f()
end

function load_layout_dir(name, dir)
	for luamap in lfs.dir(dcs_folder..dir) do
		if luamap ~= "."    and
			luamap ~= ".."   and
			luamap ~= ".svn" and
			string.sub(luamap,-4) == ".lua"
		then
			local luamap_wout_ext = string.sub(luamap, 1, -5)
			load_layout(name.."_"..luamap_wout_ext, dir, luamap)
		end
	end
end

local function getCombosName(combos)
	if combos == nil then
		return EMPTY
	end

	local comboName = ''
	for j, combo in pairs(combos or {}) do
		if comboName ~= '' then
			comboName  = comboName .. '; '
		end
		local refm = combo.reformers or {}
		table.insert(refm, 1, combo.key)
		-- return the first one found
		return '"'..comboName .. table.concat(refm, ' ')..'"'
	end
	return comboName
end

-- MAIN FLOW
for name,dir in pairs(getVariants()) do
	-- do some name formatting
	name = string.upper(name)
	-- combined arms
	if name == 'INPUT' then
		name = 'CA'
	end
	-- ignore variants other then realistic (_easy, _gunner, etc)
--	if not string.find(aircraft, '_') then
		--load_layout_dir(aircraft.."_joystick", dir.."/joystick/")
		load_layout_dir(name.."_keyboard", dir.."/keyboard/")
		print(name..':\t\t'..dir)
--	end
end

prefix = 'phase1/'
lfs.mkdir(prefix)

for name, plane in pairs(planes) do
	local file = io.open(prefix..name .. '.txt', 'w')
	local file_conflict = nil
	local tb = {}
	for i, command in pairs(plane.keyCommands or {}) do
		local cmb  = getCombosName(command.combos)
		local data = (command.name or '') .. '\t' .. (command.category or '') .. '\n'
		if tb[cmb] == nil then
			tb[cmb] = data
		elseif cmb ~= EMPTY then
			if not file_conflict then
				file_conflict = io.open(prefix..name..'.txt.conflict', 'w')
			end
			file_conflict:write("CONFLICT:\n")
			file_conflict:write('\t'..cmb..'\t'..tb[cmb])
			file_conflict:write('\t'..cmb..'\t'..data)
		end
		file:write(cmb..'\t' ..
				   (translate(command.name) or '')    ..'\t' ..
				   (translate(command.category)or '') ..'\n')
	end
	for i, command in pairs(plane.axisCommands or {}) do
		file:write(getCombosName(command.combos)               .. '\t' ..
				   (translate(command.name) or '')     .. '\t' ..
				   (translate(command.category) or '') .. '\n')
	end
	file:close()

	if file_conflict then
		file_conflict:close()
	end
end

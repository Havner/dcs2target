-- CONFIGURATION

local dcs_folder = arg[1]..'/'

local modules = {
	'Mods/aircraft/Flaming Cliffs/Input/a-10a/',
	'Mods/aircraft/Flaming Cliffs/Input/f-15c/',
	'Mods/aircraft/Flaming Cliffs/Input/mig-29/',
	'Mods/aircraft/Flaming Cliffs/Input/mig-29c/',
	'Mods/aircraft/Flaming Cliffs/Input/mig-29g/',
	'Mods/aircraft/Flaming Cliffs/Input/su-25/',
	'Mods/aircraft/Flaming Cliffs/Input/su-27/',
	'Mods/aircraft/Flaming Cliffs/Input/su-33/',
	'Mods/tech/CombinedArms/Input/',
	'Mods/aircraft/A-10A/Input/a-10a/',
	'Mods/aircraft/A-10C/Input/A-10C/',
	'Mods/aircraft/A-10C/Input/A-10C_easy/',
	'Mods/aircraft/AJS37/Input/',
	'Mods/aircraft/Bf-109K-4/Input/Bf-109K-4/',
	'Mods/aircraft/Bf-109K-4/Input/Bf-109K-4_easy/',
	'Mods/aircraft/C-101/Input/C-101EB/',
	'Mods/aircraft/F-15C/Input/',
	'Mods/aircraft/F-5E/Input/F-5E/',
	'Mods/aircraft/F-5E/Input/F-5E_easy/',
	'Mods/aircraft/F-86/Input/F-86F/',
	'Mods/aircraft/F-86/Input/F-86F_easy/',
	'Mods/aircraft/FW-190D9/Input/FW-190D9/',
	'Mods/aircraft/FW-190D9/Input/FW-190D9_easy/',
	'Mods/aircraft/Hawk/Input/',
	'Mods/aircraft/Ka-50/Input/ka-50/',
	'Mods/aircraft/Ka-50/Input/ka-50_easy/',
	'Mods/aircraft/L-39C/Input/L-39C/',
	'Mods/aircraft/L-39C/Input/L-39ZA/',
	'Mods/aircraft/M-2000C/Input/M-2000C/',
	'Mods/aircraft/Mi-8MTV2/Input/Mi-8MTV2/',
	'Mods/aircraft/Mi-8MTV2/Input/Mi-8MTV2_easy/',
	'Mods/aircraft/Mi-8MTV2/Input/Mi-8MTV2_Gunner/',
	'Mods/aircraft/Mi-8MTV2/Input/Mi-8MTV2_TrackIR_Gunner/',
	'Mods/aircraft/MiG-15bis/Input/MiG-15bis/',
	'Mods/aircraft/MiG-15bis/Input/MiG-15bis_easy/',
	'Mods/aircraft/MIG-21bis/Input/MiG-21/',
	'Mods/aircraft/P-51D/Input/P-51D/',
	'Mods/aircraft/P-51D/Input/P-51D_easy/',
	'Mods/aircraft/SA342/Input/',
	'Mods/aircraft/SpitfireLFMkIX/Input/SpitfireLFMkIX/',
	'Mods/aircraft/SpitfireLFMkIX/Input/SpitfireLFMkIX_easy/',
	'Mods/aircraft/Su-25A/Input/su-25/',
	'Mods/aircraft/Su-25T/Input/su-25T/',
	'Mods/aircraft/Su-27/Input/',
	'Mods/aircraft/TF-51D/Input/TF-51D/',
	'Mods/aircraft/TF-51D/Input/TF-51D_easy/',
	'Mods/aircraft/Uh-1H/Input/UH-1H/',
	'Mods/aircraft/Uh-1H/Input/UH-1H_easy/',
	'Mods/aircraft/Uh-1H/Input/UH-1H_Gunner/',
	'Mods/aircraft/Uh-1H/Input/UH-1H_TrackIR_Gunner/',
}

-- MODULES
local gettext = require('i_18n')
local lfs = require('lfs')
gettext.set_package("input")
gettext.set_locale_dir('l10n')
gettext.init()

-- VARIABLES
local mappings = {}
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

function ignore_features(commands, features)
end

-- LOCAL HELPER FUNCTIONS
local function translate(str)
	local result = str
	if str then
		result = gettext.translate(str)
	end
	return result
end

local function getMods()
	local mods = {}
	for i, mod in pairs(modules or {}) do
		local name_path = dcs_folder..mod..'/'..'name.lua'
		local name_file = io.open(name_path)
		if name_file then
			io.close(name_file)
			local mod_name = dofile_old(name_path)
			mod_name = string.gsub(mod_name, " ", "_")
			print(mod..' -> '..mod_name)
			mods[mod_name] = mod
		end
	end
	return mods
end

function load_layout(name, dir, luamap)
	-- this is a global variable DCS sets for profiles
	folder = dir
	local f = loadfile(dcs_folder..dir..luamap)
	if f == nil then
		return
	end
	mappings[name] = f()
end

function load_layout_dir(name, dir)
	for luamap in lfs.dir(dcs_folder..dir) do
		if string.sub(luamap,-4) == ".lua" then
			local luamap_wout_ext = string.sub(luamap, 1, -5)
			load_layout(name.."_"..luamap_wout_ext, dir, luamap)
		end
	end
end

local function getCombosName(combos)
	if combos == nil or combos[1] == nil then
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
print('\n\t === FOUND MODS ===')
all_mods = getMods()

print('\n\t === PROCESSING MODS (excl duplicates) ===')
for name, dir in pairs(all_mods) do
	-- do some name formatting
	name = string.upper(name)
	--load_layout_dir(aircraft.."_joystick", dir.."/joystick/")
	load_layout_dir(name.."_keyboard", dir.."/keyboard/")
	print(dir..' -> '..name)
end

prefix = 'phase1/'
lfs.mkdir(prefix)

for name, mapping in pairs(mappings) do
	local file = io.open(prefix..name .. '.txt', 'w')
	local file_conflict = nil
	local tb = {}
	for i, command in pairs(mapping.keyCommands or {}) do
		local cmd_name = command.name or ''
		local cmd_category = command.category[1] or command.category or ''
		cmd_name = string.gsub(cmd_name, '\n', " ") -- C-101 - WTF?
		local cmb  = getCombosName(command.combos)
		local data = (cmd_name) .. '\t' .. (cmd_category) .. '\n'
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
					 (translate(cmd_name) or '')     ..'\t' ..
					 (translate(cmd_category) or '') ..'\n')
	end
	for i, command in pairs(mapping.axisCommands or {}) do
		file:write(getCombosName(command.combos)     .. '\t' ..
					 (translate(command.name) or '')     .. '\t' ..
					 (translate(command.category) or '') .. '\n')
	end
	file:close()

	if file_conflict then
		file_conflict:close()
	end
end

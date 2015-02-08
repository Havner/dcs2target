-- CONFIGURATION

local modules = {
	'../Mods/aircraft/A-10C/Input',
	'../Mods/aircraft/Bf-109K-4/Input',
	'../Mods/aircraft/F-86/Input',
	'../Mods/aircraft/FW-190D9/Input',
	'../Mods/aircraft/Ka-50/Input',
	'../Mods/aircraft/Mi-8MTV2/Input',
	'../Mods/aircraft/P-51D/Input',
	'../Mods/aircraft/Su-25T/Input',
	'../Mods/aircraft/TF-51D/Input',
	'../Mods/aircraft/Uh-1H/Input',
	'../Mods/aircraft/Flaming Cliffs/Input',
	'../Mods/tech/CombinedArms',
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

-- sometimes add '../' due to the fact we don't run in the game dir
-- sometimes don't add if the path passed already contains it
-- the scripts will be run like:
-- dofile("Config/....")
-- dofile("../Mods/....")
dofile_old = dofile
function dofile(f)
	if string.sub(f, 1, 3) == '../' then
		return dofile_old(f)
	end
	return dofile_old('../'..f)
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

local function getAircrafts()
	local aircrafts = {}
	for i,mod in pairs(modules or {}) do
		for file in lfs.dir(mod) do
			if file ~= "." and
				file ~= ".." and
				file ~= ".svn"
			then
				local attr = lfs.attributes (mod..'/'..file)
				if attr.mode == "directory" then
					local name = io.open(mod..'/'..file..'/'..'name.lua')
					if name then
						aircrafts[file] = mod..'/'..file
						io.close(name)
						print(file)
					end
				end
			end
		end
	end
	return aircrafts
end

function load_layout(name,dir,file)
	-- this is a variable DCS sets for profiles
	folder = dir..'/'
	local f = loadfile(dir..'/'..file)
	if f == nil then
		return
	end
	planes[name] = f()
end

function load_layout_folder(name,folder)
	for file in lfs.dir(folder) do
		if file ~= "."    and
			file ~= ".."   and
			file ~= ".svn" and
			string.sub(file,-4) == ".lua"
		then
			local filename_wout_ext = string.sub(file,1,-5)
			load_layout(name.."_"..filename_wout_ext,folder,file)
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
for aircraft,folder in pairs(getAircrafts()) do
	-- do some name formatting
	aircraft = string.upper(aircraft)
	-- combined arms
	if aircraft == 'INPUT' then
		aircraft = 'CA'
	end
	-- ignore variants (_easy, _gunner, etc)
--	if not string.find(aircraft, '_') then
		--load_layout_folder(aircraft.."_joystick",folder.."/joystick")
		load_layout_folder(aircraft.."_keyboard",folder.."/keyboard")
		print(folder)
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

if not OhkoMenuSettings then
    _G.OhkoMenuSettings = _G.OhkoMenuSettings or {}
    OhkoMenuSettings._path = ModPath
    OhkoMenuSettings._data_path = SavePath .. "OHKO.txt"
	OhkoMenuSettings._hooks = {}
    OhkoMenuSettings.settings = {
    	enabled = true,
		reminder = true,
		reminder_r_value = 0.21,
		reminder_g_value = 0.74,
		reminder_b_value = 0.47,
		alpha_value = 0.9,
		instant_custody = true,
		debug = false
    }

	function OhkoMenuSettings:Load()
		local file = io.open(self._data_path, "r")
		if file then
			self.settings = json.decode(file:read("*all"))
			file:close()
		end
	end

	function OhkoMenuSettings:Save()
		local file = io.open(self._data_path, "w+")
		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_OHKO", function(loc)
		loc:load_localization_file(OhkoMenuSettings._path .. "loc/english.json")
	end)

	local function get_setting(name)
		local settings = OhkoMenuSettings.settings
		if name == false then
			name = true
		elseif settings[hook_setting] then
			name = true
		end
		return name
	end

	function OhkoMenuSettings:Hook(hook_type, class, func_name, hook_setting, hook_func)
		if self._hooks[func_name] then
			return
		end

		local hook_id = func_name .. "_ohko"
		Hooks[hook_type](Hooks, class, func_name, hook_id, function(...)
			if get_setting("enabled") and get_setting(hook_setting) then
				hook_func(...)
			end
		end)

		self._hooks[func_name] = true
	end

	function OhkoMenuSettings:Override(class, func_name, hook_setting, override)
		local hook_id = func_name
		if self._hooks[func_name] then
			return
		end

		Hooks:OverrideFunction(class, func_name, function(...)
			if get_setting("enabled") and get_setting(hook_setting) then
				return override(...)
			else
				return original(...)
			end
		end)

		self._hooks[func_name] = true
	end
end

OhkoMenuSettings:Load()

if OhkoMenuSettings.settings.debug then
	log("[OHKO] [SAVED] Is enabled or disabled: " .. tostring(OhkoMenuSettings.settings.enabled))
	log("[OHKO] [SAVED] Reminder is enabled or disabled: " .. tostring(OhkoMenuSettings.settings.reminder))
	log("[OHKO] [SAVED] Instant custody is enabled or disabled: " .. tostring(OhkoMenuSettings.settings.instant_custody))
	log("[OHKO] [SAVED] Reminder red value is: " .. tostring(OhkoMenuSettings.settings.reminder_r_value))
	log("[OHKO] [SAVED] Reminder green value is: " .. tostring(OhkoMenuSettings.settings.reminder_g_value))
	log("[OHKO] [SAVED] Reminder blue value is: " .. tostring(OhkoMenuSettings.settings.reminder_b_value))
	log("[OHKO] [SAVED] Reminder alpha value is: " .. tostring(OhkoMenuSettings.settings.alpha_value))
end

local required = {}
if RequiredScript and not required[RequiredScript] then
	local fname = OhkoMenuSettings._path .. RequiredScript:gsub(".+/(.+)", "lua/%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	required[RequiredScript] = true
end
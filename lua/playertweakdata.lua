if not OhkoMenuSettings.settings.enabled then
	return
end

Hooks:OverrideFunction(PlayerTweakData, "_set_singleplayer", function(self, ...)
	self.damage.REGENERATE_TIME = 0.00001
end)

Hooks:PreHook(PlayerTweakData, "init", "ohko_init", function(self, ...)
	self.damage = {}
	self.damage.REGENERATE_TIME = 0.0001
end)
if not OhkoMenuSettings.settings.enabled then
	return
end

Hooks:PostHook(UpgradesTweakData, "_init_pd2_values", "ohko__init_pd2_values", function(self, ...)
	self.values.player.melee_damage_dampener = {
		0
	}
end)
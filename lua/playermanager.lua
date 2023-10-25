if not OhkoMenuSettings.settings.enabled then
	return
end

Hooks:PostHook(PlayerManager, "spawned_player", "ohko_spawned_player", function(self, id, unit, ...)
	log("SPAWNED!")
	local player = _player or self:player_unit()

	player:character_damage():set_health(0.00001)
	player:character_damage():_max_health(0.00001)
	player:character_damage():set_armor(0)
end)

Hooks:PostHook(PlayerManager, "check_skills", "ohko_check_skills", function(self)
    self._super_syndrome_count = 0
end)
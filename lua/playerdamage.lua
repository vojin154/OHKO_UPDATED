local custody = false
OhkoMenuSettings:Hook("PostHook", PlayerDamage, "_call_listeners", false, function(self, damage_info)
	if (not alive(self._unit)) or self._god_mode or self._invulnerable or self._mission_damage_blockers.invulnerable then
		return
	end

	if OhkoMenuSettings.settings.instant_custody then
		if custody then
			custody = false
			return
		end

		custody = true
		MenuCallbackHandler:debug_goto_custody() --This calls _call_listeners (The function we are hooking right now) again meaning we get stuck in a loop
	else
		--Sadly :_check_bleed_out() checks if health is 0, so I gotta just copy-paste stuff
		managers.environment_controller:set_last_life(Application:digest_value(self._revives, false) <= 1)

		if Application:digest_value(self._revives, false) == 0 then
			self._down_time = 0
		end

		self._bleed_out = true
		self._current_state = nil

		managers.player:set_player_state("bleed_out")

		self._critical_state_heart_loop_instance = self._unit:sound():play("critical_state_heart_loop")
		self._slomo_sound_instance = self._unit:sound():play("downed_slomo_fx")
		self._bleed_out_health = Application:digest_value(tweak_data.player.damage.BLEED_OUT_HEALTH_INIT * managers.player:upgrade_value("player", "bleed_out_health_multiplier", 1), true)

		self:_drop_blood_sample()
		self:on_downed()
	end
end)

OhkoMenuSettings:Override(PlayerDamage, "damage_fall", false, function(self, data, ...)
	local damage_info = {
		result = {
			variant = "fall",
			type = "hurt"
		}
	}
	local is_free_falling = self._unit:movement():current_state_name() == "jerry1"

	if self._god_mode and not is_free_falling or self._invulnerable or self._mission_damage_blockers.invulnerable then
		self:_call_listeners(damage_info)

		return
	elseif self:incapacitated() then
		return
	elseif self._unit:movement():current_state().immortal then
		return
	elseif self._mission_damage_blockers.damage_fall_disabled then
		return
	end

	local height_limit = 500
	local death_limit = height_limit

	if data.height < height_limit then
		return
	end

	local die = death_limit < data.height

	self._unit:sound():play("player_hit")
	managers.environment_controller:hit_feedback_down()
	managers.hud:on_hit_direction(Vector3(0, 0, 0), die and HUDHitDirection.DAMAGE_TYPES.HEALTH or HUDHitDirection.DAMAGE_TYPES.ARMOUR, 0)

	if self._bleed_out and not is_free_falling then
		return
	end

	local health_damage_multiplier = 0

	if die then
		managers.player:force_end_copr_ability()

		self._check_berserker_done = false

		self:set_health(0)

		if is_free_falling then
			self._revives = Application:digest_value(1, true)

			self:_send_set_revives()
		end
	else
		health_damage_multiplier = managers.player:upgrade_value("player", "fall_damage_multiplier", 1) * managers.player:upgrade_value("player", "fall_health_damage_multiplier", 1)

		self:change_health(-(tweak_data.player.fall_health_damage * health_damage_multiplier))
	end

	if die or health_damage_multiplier > 0 then
		local alert_rad = tweak_data.player.fall_damage_alert_size or 500
		local new_alert = {
			"vo_cbt",
			self._unit:movement():m_head_pos(),
			alert_rad,
			self._unit:movement():SO_access(),
			self._unit
		}

		managers.groupai:state():propagate_alert(new_alert)
	end

	local max_armor = self:_max_armor()

	if die then
			self:set_armor(0)
	else
		self:change_armor(-max_armor * managers.player:upgrade_value("player", "fall_damage_multiplier", 1))
	end

	SoundDevice:set_rtpc("shield_status", 0)
	self:_send_set_armor()

	self._bleed_out_blocked_by_movement_state = nil

	managers.hud:set_player_health({
		current = self:get_real_health(),
		total = self:_max_health(),
		revives = Application:digest_value(self._revives, false)
	})
	self:_send_set_health()
	self:_set_health_effect()
	self:_damage_screen()
	self:_check_bleed_out(nil, true)
	self:_call_listeners(damage_info)

	return true
end)

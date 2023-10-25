if not OhkoMenuSettings.settings.enabled then
	return
end

local old__regenerated = PlayerDamage._regenerated
local old_change_health = PlayerDamage.change_health
local old_restore_health = PlayerDamage.restore_health
local old_change_armor = PlayerDamage.change_armor
local old__regenerate_armor = PlayerDamage._regenerate_armor
local old_restore_armor = PlayerDamage.restore_armor
local old_damage_fall = PlayerDamage.damage_fall
local old__check_bleed_out = PlayerDamage._check_bleed_out
local old__send_set_health = PlayerDamage._send_set_health
local old_set_health = PlayerDamage.set_health

Hooks:OverrideFunction(PlayerDamage, "down_time", function(...)
	return 0
end)

Hooks:PreHook(PlayerDamage,"on_downed", "ohko_down", function(self, ...)
	if OhkoMenuSettings.settings.instant_custody then
		self._down_time = 0
	end
end)

--[[Hooks:OverrideFunction(PlayerDamage, "_regenerated", function(self, no_messiah, ...)
		self:set_health(self:_max_health())
		self:_send_set_health()
		self:_set_health_effect()

		self._said_hurt = false
		self._revives = Application:digest_value(0, true)

		self:_send_set_revives(true)

		self._revive_health_i = 1

		managers.environment_controller:set_last_life(false)

		self._down_time = tweak_data.player.damage.DOWNED_TIME

		if not no_messiah then
			self._messiah_charges = managers.player:upgrade_value("player", "pistol_revive_from_bleed_out", 0)
		end
end)]]


Hooks:PostHook(PlayerDamage, "_regenerated", "ohko__regenerated", function(self, no_messiah)
	self:set_health(0.00001)
	self:_send_set_health()
	self:_set_health_effect()

	self._revives = Application:digest_value(0, true)
	self:_send_set_revives(true)
end)


Hooks:PreHook(PlayerDamage, "_max_health", "CHANGEME_PlayerDamage__max_health", function(self)
	return 0.00001
end)

Hooks:OverrideFunction(PlayerDamage, "change_health", function(self, change_of_health, ...)
	self:_check_update_max_health()
	--DONT CHANGE
	--ALREADY HAD ALOT OF FUCKING WITH THIS
	return self:set_health(0)
end)

Hooks:PostHook(PlayerDamage, "change_armor", "ohko_change_armor", function(self, change, ...)
	self:set_armor(0)
end)

Hooks:PostHook(PlayerDamage, "_regenerate_armor", "ohko_regenerate_armor", function(self, no_sound, ...)
	self._regenerate_speed = nil
	self:set_armor(0)
	self:_send_set_armor()
end)

Hooks:PostHook(PlayerDamage, "restore_armor", "ohko_restore_armor", function(self, armor_restored, ...)
	if self._dead or self._bleed_out or self._check_berserker_done then
		return
	end

	self:set_armor(0)
	self:_send_set_armor()
end)

Hooks:OverrideFunction(PlayerDamage, "damage_fall", function(self, data, ...)
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

Hooks:OverrideFunction(PlayerDamage, "_check_bleed_out", function(self, can_activate_berserker, ignore_movement_state, ignore_reduce_revive, ...)
		if self:get_real_health() == 0 and not self._check_berserker_done then
			if self._unit:movement():zipline_unit() then
				self._bleed_out_blocked_by_zipline = true

				return
			end

			if not ignore_movement_state and self._unit:movement():current_state():bleed_out_blocked() then
				self._bleed_out_blocked_by_movement_state = true

				return
			end

			if managers.player:has_activate_temporary_upgrade("temporary", "copr_ability") and managers.player:has_category_upgrade("player", "copr_out_of_health_move_slow") then
				return
			end

			local time = Application:time()

			if can_activate_berserker and not self._check_berserker_done then
				local has_berserker_skill = managers.player:has_category_upgrade("temporary", "berserker_damage_multiplier")

				if has_berserker_skill and not self._disable_next_swansong then
					managers.hud:set_teammate_condition(HUDManager.PLAYER_PANEL, "mugshot_swansong", managers.localization:text("debug_mugshot_downed"))
					managers.player:activate_temporary_upgrade("temporary", "berserker_damage_multiplier")

					self._current_state = nil
					self._check_berserker_done = true

					if alive(self._interaction:active_unit()) and not self._interaction:active_unit():interaction():can_interact(self._unit) then
						self._unit:movement():interupt_interact()
					end

					self._listener_holder:call("on_enter_swansong")
				end

				self._disable_next_swansong = nil
			end

			self._hurt_value = 0.2
			self._damage_to_hot_stack = {}

			managers.environment_controller:set_downed_value(0)
			SoundDevice:set_rtpc("downed_state_progression", 0)

			if not self._check_berserker_done or not can_activate_berserker then
				if not ignore_reduce_revive then
					self._revives = Application:digest_value(Application:digest_value(self._revives, false) - 1, true)

					self:_send_set_revives()
				end

				self._check_berserker_done = nil

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
		elseif not self._said_hurt and self:get_real_health() / self:_max_health() < 0.2 then
			self._said_hurt = true

			PlayerStandard.say_line(self, "g80x_plu")
		end
end)


Hooks:PostHook(PlayerDamage, "_check_update_max_armor", "CHANGEME_PlayerDamage__check_update_max_armor", function(self)
	self._armor = Application:digest_value(0, true)
	self._current_max_armor = 0
end)

Hooks:OverrideFunction(PlayerDamage, "_max_armor", function()
	return 0
end)

Hooks:PostHook(PlayerDamage, "set_armor", "CHANGEME_PlayerDamage_set_armor", function(self, armor)
	if self._armor_change_blocked then
		return
	end

	self._armor = Application:digest_value(0, true)
end)

--[[Hooks:OverrideFunction(PlayerDamage, "_send_set_health", function(self, ...)
	--log("hurt")
	if self._unit:network() then
		local hp = 0.00001
		local max_mul = 1

		self._unit:network():send("set_health", math.clamp(hp, 0, 100), max_mul)

		if self:get_real_health() - self:_max_health() > 0.001 then
			managers.mission:call_global_event("player_damaged")
		end
	end
end)]]


--[[local old_PlayerDamage_set_health = PlayerDamage.set_health
function PlayerDamage:set_health(health)
	local result = old_PlayerDamage_set_health(self, health)
		self._health = 0.00001

		self:_send_set_health()
		self:_set_health_effect()
	return result
end]]

--[[Hooks:PreHook(PlayerDamage, "set_health", "ohko_set_health", function(self, health, ...)
	self._health = 0.00001

	self:_send_set_health()
	self:_set_health_effect()

	return false
end)]]
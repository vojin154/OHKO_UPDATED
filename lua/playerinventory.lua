if not OhkoMenuSettings.settings.enabled then
	return
end

Hooks:PostHook(PlayerInventory, "_start_feedback_effect", "ohko__start_feedback_effect", function(self, end_time, ...)
	self._jammer_data.heal = 0
end)
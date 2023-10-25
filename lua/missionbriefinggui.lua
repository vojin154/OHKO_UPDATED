Hooks:PostHook(MissionBriefingGui, "init", "OHKO_ready_text", function (self)
    self._my_text = self._panel:text({
        text = "One Hit Knock Out ENABLED",
		font = tweak_data.menu.pd2_large_font,
        font_size = 20,
        color = Color(OhkoMenuSettings.settings.reminder_r_value, OhkoMenuSettings.settings.reminder_g_value, OhkoMenuSettings.settings.reminder_b_value),
		alpha = OhkoMenuSettings.settings.alpha_value
    })
    
    local x, y, w, h = self._my_text:text_rect()
    self._my_text:set_size(w, h)

    self._my_text:set_rightbottom(self._ready_button:right() + 35, self._ready_button:y())
    if not (OhkoMenuSettings.settings.enabled and OhkoMenuSettings.settings.reminder) then
        self._my_text:hide()
    end
    OhkoMenuSettings.menu_text = self._my_text
end)
Hooks:PostHook(MissionBriefingGui, "init", "OHKO_ready_text", function (self)
    local text = self._panel:text({
        text = "One Hit Knock Out ENABLED",
		font = tweak_data.menu.pd2_large_font,
        font_size = 20,
        color = Color(OhkoMenuSettings.settings.reminder_r_value, OhkoMenuSettings.settings.reminder_g_value, OhkoMenuSettings.settings.reminder_b_value),
		alpha = OhkoMenuSettings.settings.alpha_value
    })
    
    local _, _, w, h = text:text_rect()
    text:set_size(w, h)

    text:set_rightbottom(self._ready_button:right() + 35, self._ready_button:y())
    if (not OhkoMenuSettings.settings.enabled) or (not OhkoMenuSettings.settings.reminder) then
        text:hide()
    end
    OhkoMenuSettings.menu_text = text
end)
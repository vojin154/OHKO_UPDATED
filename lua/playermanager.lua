OhkoMenuSettings:Hook("PostHook", PlayerManager, "check_skills", false, function(self)
	self._super_syndrome_count = 0
end)
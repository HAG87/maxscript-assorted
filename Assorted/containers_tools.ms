fn cont_content c =
(
	if isKindOf c Container then (
		local nd
		c.GetContentNodes true &nd
		selectMore nd
	)
)
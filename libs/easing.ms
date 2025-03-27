-- Ease-In Algorithm in MaxScript
(
	struct easing
	(
		-- Function to calculate ease-in based on a cubic function
		fn easeInCubic t = t^3,
		
		-- Function to calculate ease-in based on a quadratic function
		fn easeInQuad t = t^2,
			
		-- Function to calculate ease-in based on a sinusoidal function
		fn easeInSine t =
		(
			1 - cos (t * pi / 2.0)
		),

		-- Function to calculate ease-in based on an exponential function
		fn easeInExpo t =
		(
			if t == 0 then 0 else (2.0 ^ (10 * (t - 1)))
		),

		-- Function to calculate ease-in based on a circular function
		fn easeInCirc t =
		(
			if t == (t as integer == 1) then 1 else 1 - sqrt (1 - t * t)
			t
		),

		-- Function to calculate ease-in based on a back function
		fn easeInBack t s:1.70158 =
		(
			t^2 * ((s + 1) * t - s)
		),
		-- Function to calculate ease-out based on a bounce function (used for ease-in bounce)
		fn easeOutBounce t =
		(
			if t < (1 / 2.75) then
				7.5625 * t^2
			else if t < (2 / 2.75) then
			(
				t = t - (1.5 / 2.75)
				7.5625 * t^2 + 0.75
			)
			else if t < (2.5 / 2.75) then
			(
				t = t - (2.25 / 2.75)
				7.5625 * t^2 + 0.9375
			)
			else
			(
				t = t - (2.625 / 2.75)
				7.5625 * t^2 + 0.984375
			)
		),
		-- Function to calculate ease-in based on a bounce function
		fn easeInBounce t =
		(
			1 - easeOutBounce (1 - t)
		),
		-- Function to interpolate between two values using an easing function
		fn interpolateEase startValue endValue t easingFunction =
		(
			local delta = endValue - startValue
			local easedT = easingFunction t
			startValue + delta * easedT			
		)

	)
)
ea = easing()
-- Test the ease-in functions
/*
for t = 0.0 to 1.0 by 0.1 do
(
	-- format "t: % - EaseInCubic: %\n" t (ea.easeInCubic t)
	-- format "t: % - EaseInQuad: %\n" t (ea.easeInQuad t)
	-- format "t: % - EaseInSine: %\n" t (ea.easeInSine t)
	-- format "t: % - EaseInExpo: %\n" t (ea.easeInExpo t)
	-- format "t: % - EaseInCirc: %\n" t (ea.easeInCirc t)
	-- format "t: % - EaseInBack: %\n" t (ea.easeInBack t)
	-- format "t: % - EaseInBounce: %\n" t (ea.easeInBounce t)
	ea.interpolateEase 0.0 1.0 t easeInBounce
)
*/
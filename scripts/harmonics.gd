extends RefCounted

class_name Harmonics

static func generate_harmonic_properties(n: int) -> Array:

	var harmonics: Array = []
	for i in range(n):
		var harmonic = {
			"index": i + 1,
			# Amplitudes often decay as the harmonic order increases (1/n)
			"amplitude": randf_range(0,PI*0.0615) / PI,
			"frequency": randf_range(0, float(i + 1)),
			"phase": 0.0
		}
		harmonics.append(harmonic)
	
	return harmonics

static func generate_organic_shape_points(harmonics: Array, base_radius: float = 150.0, resolution: int = 120) -> PackedVector2Array:
	var points = PackedVector2Array()

	for i in range(resolution + 1):
		var angle = (float(i) / float(resolution)) * TAU
		var radius_offset = 0.0
		
		for h in harmonics:
			var freq = h["frequency"]
			var amp = h["amplitude"] * 40.0 
			var phase = h.get("phase", 0.0)
			
			radius_offset += amp * sin(angle * freq + phase)
		
		var current_radius = base_radius + radius_offset

		var x = cos(angle) * current_radius
		var y = sin(angle) * current_radius

		points.append(Vector2(x, y))
		
	return points

class_name AsteroidMeshFactory
extends RefCounted
## Процедурный low-poly астероид: UV-сфера, смещённая шумом, с плоскими нормалями.
## Каждый астероид уникален, ассеты не нужны.

const RINGS := 7
const SEGMENTS := 10


static func build(radius: float, seed_value: int) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.2
	noise.fractal_octaves = 3
	var stretch := Vector3(randf_range(0.8, 1.25), randf_range(0.7, 1.1), randf_range(0.8, 1.25))

	var grid: Array[PackedVector3Array] = []
	for r in RINGS + 1:
		var theta := PI * float(r) / RINGS
		var row := PackedVector3Array()
		for s in SEGMENTS:
			var phi := TAU * float(s) / SEGMENTS
			var dir := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
			var bump := noise.get_noise_3dv(dir * 1.5)
			row.append(dir * radius * (1.0 + bump * 0.6) * stretch)
		row.append(row[0])  # замыкаем шов без трещин
		grid.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)  # плоские нормали = граненый стиль
	for r in RINGS:
		for s in SEGMENTS:
			var a := grid[r][s]
			var b := grid[r][s + 1]
			var c := grid[r + 1][s]
			var d := grid[r + 1][s + 1]
			# Godot: лицевая сторона — обход по часовой стрелке
			if r != 0:
				st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
			if r != RINGS - 1:
				st.add_vertex(b); st.add_vertex(c); st.add_vertex(d)
	st.generate_normals()
	return st.commit()

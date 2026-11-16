class_name Layers
extends RefCounted
## Битовые маски физических слоёв. Единственный источник правды —
## имена слоёв продублированы в project.godot → [layer_names].

const PLAYER := 1 << 0     # слой 1
const ASTEROIDS := 1 << 1  # слой 2
const ENEMIES := 1 << 2    # слой 3

# Street-life validation

Godot 4.7.2, Forward+, RTX 3080 Laptop GPU, existing graphical benchmark route.
One original-code run and one updated-code run; frame times are indicative,
not a guaranteed FPS improvement. Both runs used the same renderer and hardware.

| Level | Original frame time | Updated frame time | Original draw calls | Updated draw calls |
|---|---:|---:|---:|---:|
| Caledonian | 38.973 ms | 37.849 ms | 2480.5 | 2219.8 |
| Monaco | 37.864 ms | 36.415 ms | 1551.0 | 1438.5 |

- Asset validation passed for all 15 models: one surface, vertex palette enabled,
  at most 5,000 triangles, grounded Y-up bounds, shared mesh resources.
- Inspected the rendered Godot shelf (`preview.png`).
- Street-life soak passed: 600 simulated seconds.
- Monaco scene smoke test passed.
- `make check` passed geometry, input, services, progression, delivery and asset
  checks before stopping in `ride_scene_smoke.gd`. The same three failures were
  reproduced in a separate copy with the original street-life and traffic code:
  civic-hill layout, road-audit grades, and hanging-garland clearance.
- Both original and updated graphical benchmarks reported the same seven leaked
  texture RIDs at renderer shutdown.

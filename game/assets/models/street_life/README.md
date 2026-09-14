# Street-life toy kit

Original Blender-built assets for both islands: rounded painted vehicles, chunky
wheels, dark blue opaque windows, oversized heads, warm satin colors, clear
species silhouettes. No external textures or third-party models.

- `car`, `taxi`, `bus`, `pickup`, `truck`: compact road vehicles.
- `person_0`–`person_3`: cap, scarf/bun, backpack, and sunglasses variants.
- `dog`, `fox`, `horse`, `cow`, `pig`, `goose`: wildlife and farm residents.

Each GLB has one combined mesh, one surface, and a linear vertex-color palette.
The game explicitly enables vertex colors with a shared satin material and
reuses imported mesh resources. Models are 1,836–4,968 triangles; exact counts
are in `mesh_budget.json`. Godot generates import LODs. No textures, skeletons,
transparent glazing, or additional lights are needed. Farm animals retain the
existing gentle motion. These are static toy figures, without limb/wheel rigs.

Ground-plane origins, metres, Y up, forward -Z. The factory compensates for the
existing agent origin offsets. Longer vehicles have matching collision lengths
and following distances. Traffic density and routes remain managed by each level.

Editable shelf: `art/street_life/street_life.blend` (outside the runtime project).
Rebuild from the repository root with:

```sh
blender --background --python scripts/build_street_life.py
```

The script can also be executed through Blender MCP; it creates its own scene.
Runtime assets are exported only from that scene. Validate with `make check`,
or run `godot --headless --path game --script res://tests/street_life_assets.gd`.
Add `-- --capture` with a graphical renderer to save a model shelf to
`/tmp/bikegame_street_life.png`.

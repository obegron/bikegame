# Bikegame

A first-person delivery cycling game built with Godot 4. The game consumes ordinary
joypad input, including the Linux virtual controller emitted by `ftms2pad`.

The working project name is intentionally generic until the core riding loop proves
fun.

## Current build

The repository now contains a playable compact MVP with a start-level selector:

- first-person cycling with inertial steering, camera lean/bob, and visible hands;
- **Caledonian Island**, a roughly 400×300-metre European island city with rolling terrain, a raised
  crooked-lane old town and irregular market square, canal and river bridges,
  protected cycle tracks, a gatehouse, staggered heritage terraces,
  gardens, hill village, orchard cottages, beaches, cliffs, and a connected
  coastal cycle loop; Meadowcroft Farm adds a barn, fenced pasture, pond, horse,
  cow, two pigs, five geese, and farmer deliveries;
- **Monaco Corniche**, a fictional Mediterranean island with a dense hillside
  harbour city, rugged northern cliffs, two corniches, paired switchbacks, a
  casino circuit, illuminated road tunnel, Port Hercule marina and yachts,
  palace, museum, Larvotto beach, palms, cypress gardens, and its own restaurants,
  customers, traffic routes, and courier minimap;
- a toy-box art direction shared by both islands: satin painted facades,
  rounded building edges and little cars, oversized character heads, sculpted
  palm crowns, coral cycle lanes, teal roads, turquoise water, and quiet terrain
  colors; warm sunlight and cool fill give the clean geometry volume;
- procedural pillowy clouds, retained dynamic stars and weather, compact pickup
  markers, and a delivery card that fits its content; terrain-conforming road
  layers prevent grass and paving from breaking through bends and junctions;
- Cornwall/Prague-inspired cornices, dormers, chimneys, window boxes, climbing
  plants, market garlands, Gothic spires, and batched trees, hedges and flowers;
- continuous time-of-day lighting, changing clear/overcast/fog/rain weather,
  working street lamps, an automatic bicycle headlight, and time-specific order
  mixes;
- the full offer → pickup → drop-off → rating → tip → pay loop, with seven named
  illustrated customers and rating-sensitive delivery dialogue;
- a north-up courier minimap with rider heading, route, and objective;
- signal-aware traffic, pedestrians, dogs, foxes, farm animals, and small daytime
  bird flocks;
- persistent game and exercise-proxy stats, achievements, and cosmetic bike styles;
- onboarding, pause/options, keyboard remapping, and generated feedback audio; and
- optional ENet hosting/joining with server-owned clock and orders.

Open `game/project.godot` in Godot 4.3 or newer, run the project, and choose either
level. Progress is shared between them.

### Controls

| Action | Keyboard | Ordinary gamepad | `ftms2pad` |
|---|---|---|---|
| Steer | A/D or arrows | left stick X | torso lean / `ABS_X` |
| Pedal | W or up | left stick forward | bike speed / `ABS_Y` |
| Brake | S or down | east button | S or down |
| Accept order | Space or Enter | south button | right wrist / `BTN_SOUTH` |
| Decline order | Q or Backspace | west button | left wrist / `BTN_WEST` |
| Reset position | R | north button | R |
| Pause/options | Escape | start button | both wrists / `BTN_START` |

`ftms2pad` owns the unusual Y-axis convention: with the supplied inverted profile,
rest is +1 and maximum pedaling is -1. `BikeInputAdapter` is the only game code that
knows this. Keyboard controls can be rebound from the Escape menu.
Order offers are optional: accept, decline, or let the countdown expire.

## Try the physical input path

The nested `bikestear/` checkout is a separate Git repository, ignored by the parent
and outside Godot's `res://`. It contains optional wrist gestures for accept,
decline, and menu, but the supplied profile still needs physical-camera testing:

```bash
cd bikestear
uv run ftms2pad monitor \
  --profile ../integrations/ftms2pad/bikegame.yaml \
  --bike sim
```

After calibration, replace `monitor` with `run`, start the Godot project, and confirm
that Godot detects the `ftms2pad` device. Use `monitor` first to tune the 400 ms
single-wrist hold and 900 ms two-wrist menu hold, or set
`vision.gesture: disabled` while validating riding.

## Multiplayer

Press Escape and choose **Host** or **Join localhost**. The prototype uses UDP port
27820. Peers exchange only position, heading, speed, collision count, and abstract
delivery state—never BLE or camera data.

## Project map

```text
docs/MILESTONES.md                  delivery plan and acceptance gates
integrations/ftms2pad/              external input profile
game/project.godot                  isolated Godot project root
game/scenes/level_select.tscn       startup level chooser
game/scenes/gameplay_shell.tscn     shared courier systems and HUD
game/scenes/delivery_game.tscn      Caledonian Island gameplay scene
game/scenes/monaco_game.tscn        Monaco Corniche gameplay scene
game/scenes/phase_zero/             retained input-feel course
game/src/core/                      clock, orders, economy, progression
game/src/world/                     level generators, lighting, street-life pools
game/src/agents/                    cars, pedestrians, wildlife
game/src/input/                     engine-facing input contract
game/src/player/                    bicycle movement
game/src/network/                   optional ENet replication
game/src/ui/                        HUD, onboarding, pause/options
game/tools/world_audit.gd            SVG/JSON procedural-map audit
scripts/check_project.sh            repository/headless-Godot check
```

Validation commands:

```bash
make check          # runtime, mappings, services, five deliveries, real movement
make benchmark      # graphical 720p Caledonian/Monaco A/B performance route
make audit-map      # Monaco geometry audit as SVG + JSON in /tmp/bikegame-audit
make soak-check     # accelerated 600-second street-life soak
make network-check  # real ENet server/client loopback

cd bikestear
make test           # ftms2pad deterministic suite
```

Pass `BENCHMARK_FLAGS="-- --level monaco"` to benchmark only Monaco without
constructing the Caledonian scene first.

### World audit maps

Run `make audit-map` before a visual road/building pass. It instantiates the exact
procedural gameplay scene in Godot, then writes:

- `/tmp/bikegame-audit/monaco_audit.svg` — coast, roads, building footprints, and
  numbered red/amber findings for a quick top-down investigation;
- `/tmp/bikegame-audit/monaco_audit.json` — exact positions and measurements for
  road overlap, surface grade/cross-slope, sharp vertical or horizontal bends,
  submerged road, nested collision and low visual-geometry obstructions
  (including compound landmarks and parasols), unreachable objectives, and
  floating or buried foundations.

No Python environment or additional package is needed. Use
`make audit-map AUDIT_LEVEL=caledonian` for the first level, or
`make audit-map AUDIT_LEVEL=all AUDIT_OUTPUT=/tmp/my-audit` for both. Add
`AUDIT_FLAGS=--fail-on-errors` if the audit should act as a CI gate.

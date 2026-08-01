# Delivery Cycling Game milestones

The milestones are ordered by risk: first prove that riding feels good, then prove
the delivery loop, and only then spend time on city content. A milestone is complete
only when its exit gate can be demonstrated in a fresh run.

## Implementation status

| Milestone | Status | Evidence / remaining manual gate |
|---|---|---|
| M0 Foundation | Complete | `make check`; isolated `game/` project root |
| M1 First ride | Controls validated | Keyboard controls/performance accepted; physical `ftms2pad` ride deferred |
| M2 Delivery slice | Complete | Automated five-delivery scene test and deterministic economy bounds |
| M3 District/day | Implemented | Selectable Caledonian and Monaco levels; Monaco road audit reports 342 graded corridors and zero static lane obstructions |
| M4 Street life | Implemented | Signal-aware cars, pooled birds, and accelerated 600-second soak coverage |
| M5 Progression/art | Implemented | PBR city materials, batched CC0 foliage, persistence, cosmetics, onboarding, options, audio |
| M6 Accept gesture | Code complete | 30 `bikestear` tests pass; physical false-positive check pending |
| M7 Multiplayer | Prototype complete | ENet loopback passes; two-machine cooperative ride remains a manual gate |

## Scope rules

- `bikestear/` is a separate nested Git repository outside the `game/` Godot project
  root. Gesture changes stay there for a separate commit.
- The game depends only on Godot's ordinary joypad API, never on BLE, vision, or
  `ftms2pad` Python modules.
- Physical-rig validation happens on Linux. Keyboard and a normal gamepad keep
  development unblocked elsewhere.
- Gray-box mechanics precede production art.
- Collisions can reduce score or time, but never hard-fail or reset a delivery.
- Multiplayer and the CV accept gesture are explicitly post-MVP.

## M0 — Repository foundation

**Status:** Complete.

**Outcome:** A new contributor can open one Godot project and understand the path to
the first playable test.

Deliverables:

- Godot project skeleton and one launchable gray-box scene.
- `BikeInputAdapter` boundary for `steer`, `throttle`, `brake`, and `accept`.
- Keyboard, ordinary-gamepad, and `ftms2pad` mappings.
- External `bikegame.yaml` profile and setup notes.
- A local check command and documented project layout.

Exit gate:

- `make check` passes.
- With Godot installed, the project starts without parser/resource errors.
- The nested reference checkout does not appear in the project's Git changes.

## M1 — First ride / input-feel validation

**Status:** Keyboard controls and game-side performance accepted. Trainer/camera,
stale-input, and combined-process measurements are deferred by request.

**Outcome:** Ten minutes of first-person riding feels controllable and encourages
another run.

Work items:

- Tune acceleration, coasting, braking, maximum speed, steering inertia, and camera
  lean on keyboard/gamepad.
- Add a compact test route with slalom, narrow gate, wide turn, and collision counter.
- Calibrate the supplied profile against `--bike sim`, then the real trainer.
- Record frame rate, vision inference time, input staleness, and game frame time while
  both processes share the Linux machine.
- Decide between `speed_kph` and `cadence_rpm` from observed feel; commit the chosen
  profile values.

Exit gate:

- Steering returns safely to neutral when tracking goes stale.
- Rest produces zero throttle and the configured upper range reaches full throttle.
- A rider can complete three consecutive test laps without an accidental reset or
  unexplained input spike.
- Game and input process meet a stable target of 60 game FPS and roughly 20 vision
  FPS on the riding machine, or a measured lower target is documented.

Not in this milestone: deliveries, city art, traffic, hand gestures.

## M2 — Delivery vertical slice

**Status:** Complete in the automated scene test, including five consecutive
deliveries and persisted payment.

**Outcome:** The complete order-to-payment loop is playable in gray-box form.

Work items:

- Introduce `WorldClock`, `OrderService`, and `EconomyService` behind local interfaces.
- Implement the order state machine: offered, declined/expired, accepted, pickup,
  drop-off, completed.
- Add one pickup and three drop-off points with proximity auto-collection.
- Add one-to-two-offer queue cap, route marker, timer, money, rating, and tips.
- Count collisions per active delivery and feed only the outcome into the economy.
- Save a minimal local profile for money, aggregate deliveries, and best streak.

Exit gate:

- Five deliveries can be completed back-to-back without restarting.
- Late and collision penalties produce deterministic, testable rating bounds of 1–5.
- No gameplay class reads raw joystick axes except `BikeInputAdapter`.
- Order generation can be replaced without changing the player or HUD.

## M3 — MVP district and day cycle

**Status:** Implemented. The physical shared-machine performance gate remains tied
to M1 testing.

**Outcome:** Two connected compact cities support satisfying sessions without
pretending to be open worlds: the original heritage island and a steeper
Mediterranean harbour level inspired by Monaco.

Work items:

- Build a canal and river, old-town market square, heritage terraces, gardens,
  rolling outskirts, and curved outer roads as one connected route.
- Add a separately selectable Monaco map with harbour roads, corniches,
  switchbacks, a lit tunnel, dense Belle Époque/Le Rocher/modern terraces,
  recognizable Grand Prix corners, and a map-specific courier network.
- Build modular asphalt/cobble roads, protected cycle tracks, rideable bridges,
  quays, pitched-roof façades, and landmarks.
- Add continuous morning/day/noon/sunset/night lighting keyframes.
- Make order type, frequency, and tip range respond to `WorldClock`.
- Establish navigation landmarks and accessible route signage.
- Profile the combined game plus `ftms2pad` workload before the art pass.

Exit gate:

- Every pickup/drop-off pairing has a traversable route.
- Monaco's automated footprint audit finds no building, quay, retaining wall,
  traffic light, sign, parked car, or foliage inside a drivable corridor, and its
  solved road graph stays at or below a 12.5% grade.
- Each level owns its city generation, agent routes, delivery locations, and
  minimap while sharing the courier services and progression profile.
- Lighting transitions continuously and never compromises route readability.
- A full in-game day produces visibly different order mixes.
- The shared Linux machine stays within the M1 performance budget.

## M4 — Street life

**Status:** Implemented. `make soak-check` simulates 600 seconds at 30× time scale and
checks fixed pool bounds plus finite agent positions.

**Outcome:** The district feels alive without becoming a heavy traffic simulation.

Work items:

- Spline/waypoint cars with stop, yield, resume, and simple pooling.
- Synchronized modern-junction traffic lights that cars obey.
- Pedestrians with walk, wait, cross, and evade states.
- Dogs and foxes with park-biased wander/flee behavior.
- Small daytime bird flocks over the river, gardens, and old-town roofs.
- Soft collision response: brief speed loss plus a rating contribution.
- Density controls tied to district and time of day.

Exit gate:

- Agents recover when blocked and do not accumulate indefinitely.
- Ten-minute soak test has no trapped-agent growth or large frame-time spikes.
- Player collisions never hard-fail, teleport, or reset a delivery.

## M5 — Content, progression, and art

**Status:** Implemented with stylized geometry, CC0 PBR surface materials, and
batched low-poly foliage. Effort is a separate throttle-over-active-time proxy; no
watt value is invented when telemetry is absent.

**Outcome:** The MVP has enough variety and motivation for repeated exercise sessions.

Work items:

- Replace gray-box modules with a consistent stylized/low-poly kit.
- Add district variants and order pools without expanding to an open-world scale.
- Surface earned money, deliveries, rating streak, distance, and active time.
- Add an effort estimate using optional telemetry when available and a graceful
  fallback when it is not.
- Add attendance-oriented achievements and cosmetic bike/district unlocks.
- Add audio, options, remapping, pause, onboarding, and save migration/versioning.

Exit gate:

- A 30-minute session exposes no progression blocker when telemetry is unavailable.
- Exercise stats and game stats remain distinct and understandable.
- All progression unlocks are cosmetic.
- A clean install can complete onboarding with keyboard or a normal gamepad.

## M6 — CV action gestures

**Status:** Implemented in `bikestear` using wrist landmarks already produced by
MediaPipe Pose. Right wrist accepts, left wrist declines, and both wrists open the
menu after a longer hold. It adds no second inference model, releases on stale
tracking, reports cost/state in `monitor`, and emits ordinary gamepad buttons.
Physical false-positive validation is pending.

**Outcome:** Orders and the pause menu can be controlled hands-free without degrading
steering reliability.

Work items:

- First ship and test physical/ordinary buttons mapped to the three actions.
- Prototype an independent hand-region signal; do not reuse torso lean.
- Add confidence, stale handling, and a configurable 300–500 ms hold.
- Extend monitoring with gesture inference time and trigger state.
- Compare false-positive rate and CPU cost against the button baseline.

Exit gate:

- No false order or menu action occurs in a representative 30-minute ride.
- Gesture inference does not break the performance budget from M1.
- Loss of hand tracking cannot affect steering or throttle.

## M7 — Optional multiplayer

**Status:** Prototype implemented. ENet host/join, server-owned clock/orders, world
snapshots, rider interpolation, result replication, and disconnect cleanup are
present. Loopback passes; a real two-instance cooperative ride is pending.

**Outcome:** A small cooperative ride works without sending raw fitness or vision data.

Work items:

- Make `WorldClock` and `OrderService` server-authoritative.
- Replicate position, heading, animation state, and order events.
- Add interpolation, disconnect recovery, and a two-player lobby.
- Define privacy boundaries and session ownership.

Exit gate:

- Two remote players can share a complete delivery session.
- Only abstract gameplay state crosses the network.
- Single-player remains fully playable offline.

## Remaining physical/manual validation

1. Run `ftms2pad monitor` with the sim bike, then calibrate the trainer/camera.
2. Verify zero throttle at rest, stale steering return, and combined game/vision FPS.
3. Ride 30 minutes with `wrist_buttons`; record false actions and gesture cost, then
   adjust or disable it.
4. Complete a real-time 30-minute session to judge progression pacing and comfort.
5. Run host/client instances—then two machines—and complete a shared delivery before
   treating M7 as production-ready.

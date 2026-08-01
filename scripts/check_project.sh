#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_DIR=$(dirname -- "$SCRIPT_DIR")
PROJECT_DIR="$REPOSITORY_DIR/game"

required_files="
game/project.godot
game/scenes/phase_zero/phase_zero.tscn
game/src/input/bike_input_adapter.gd
game/src/player/bike_controller.gd
game/src/debug/phase_zero_course.gd
game/src/debug/input_debug_hud.gd
game/tests/input_mapping_smoke.gd
game/tests/core_services_smoke.gd
game/tests/progression_smoke.gd
game/tests/delivery_loop_smoke.gd
game/tests/ride_scene_smoke.gd
game/tests/minimap_smoke.gd
game/tests/bridge_ride_smoke.gd
game/tests/level_selection_smoke.gd
game/tests/monaco_scene_smoke.gd
game/tests/monaco_road_audit.gd
game/tests/level_performance_benchmark.gd
game/tools/world_audit.gd
game/src/ui/courier_minimap.gd
game/src/ui/monaco_minimap.gd
game/src/world/monaco_city.gd
game/scenes/level_select.tscn
game/scenes/monaco_game.tscn
integrations/ftms2pad/bikegame.yaml
docs/MILESTONES.md
"

for relative_path in $required_files; do
	if [ ! -f "$REPOSITORY_DIR/$relative_path" ]; then
		echo "Missing required file: $relative_path" >&2
		exit 1
	fi
done

GODOT_DATA_DIR="${TMPDIR:-/tmp}/bikegame-godot-data"
GODOT_CONFIG_DIR="${TMPDIR:-/tmp}/bikegame-godot-config"
GODOT_CACHE_DIR="${TMPDIR:-/tmp}/bikegame-godot-cache"
export XDG_DATA_HOME="$GODOT_DATA_DIR"
export XDG_CONFIG_HOME="$GODOT_CONFIG_DIR"
export XDG_CACHE_HOME="$GODOT_CACHE_DIR"
RUNTIME_LOG=$(mktemp "${TMPDIR:-/tmp}/bikegame-godot-runtime.XXXXXX.log")
trap 'rm -f "$RUNTIME_LOG"' EXIT

if command -v godot4 >/dev/null 2>&1; then
	godot4 --headless --path "$PROJECT_DIR" --quit-after 2 --log-file "$RUNTIME_LOG"
	if rg -q "SCRIPT ERROR|ERROR:" "$RUNTIME_LOG"; then
		echo "Godot runtime reported errors." >&2
		exit 1
	fi
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/input_mapping_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/core_services_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/progression_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/delivery_loop_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/ride_scene_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/minimap_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/bridge_ride_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/level_selection_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/monaco_scene_smoke.gd
	godot4 --headless --path "$PROJECT_DIR" --script res://tests/monaco_road_audit.gd
elif command -v godot >/dev/null 2>&1; then
	godot --headless --path "$PROJECT_DIR" --quit-after 2 --log-file "$RUNTIME_LOG"
	if rg -q "SCRIPT ERROR|ERROR:" "$RUNTIME_LOG"; then
		echo "Godot runtime reported errors." >&2
		exit 1
	fi
	godot --headless --path "$PROJECT_DIR" --script res://tests/input_mapping_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/core_services_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/progression_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/delivery_loop_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/ride_scene_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/minimap_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/bridge_ride_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/level_selection_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/monaco_scene_smoke.gd
	godot --headless --path "$PROJECT_DIR" --script res://tests/monaco_road_audit.gd
else
	echo "Structure check passed. Godot is not installed; skipped runtime checks."
fi

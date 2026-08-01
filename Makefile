.PHONY: check benchmark visual-capture caledonian-visual-capture audit-map network-check soak-check

AUDIT_LEVEL ?= monaco
AUDIT_OUTPUT ?= /tmp/bikegame-audit
AUDIT_FLAGS ?=
VISUAL_FLAGS ?=

check:
	@./scripts/check_project.sh

benchmark:
	@xvfb-run -a env XDG_DATA_HOME=/tmp/bikegame-benchmark-data XDG_CONFIG_HOME=/tmp/bikegame-benchmark-config XDG_CACHE_HOME=/tmp/bikegame-benchmark-cache godot --path game --script res://tests/level_performance_benchmark.gd $(BENCHMARK_FLAGS)

visual-capture:
	@xvfb-run -a env XDG_DATA_HOME=/tmp/bikegame-visual-data XDG_CONFIG_HOME=/tmp/bikegame-visual-config XDG_CACHE_HOME=/tmp/bikegame-visual-cache godot --path game --script res://tests/monaco_visual_capture.gd $(VISUAL_FLAGS)

caledonian-visual-capture:
	@xvfb-run -a env XDG_DATA_HOME=/tmp/bikegame-visual-data XDG_CONFIG_HOME=/tmp/bikegame-visual-config XDG_CACHE_HOME=/tmp/bikegame-visual-cache godot --path game --script res://tests/caledonian_visual_capture.gd $(VISUAL_FLAGS)

audit-map:
	@XDG_DATA_HOME=/tmp/bikegame-audit-data XDG_CONFIG_HOME=/tmp/bikegame-audit-config XDG_CACHE_HOME=/tmp/bikegame-audit-cache godot --headless --path game --script res://tools/world_audit.gd -- --level $(AUDIT_LEVEL) --output $(AUDIT_OUTPUT) $(AUDIT_FLAGS)

network-check:
	@XDG_DATA_HOME=/tmp/bikegame-network-data XDG_CONFIG_HOME=/tmp/bikegame-network-config XDG_CACHE_HOME=/tmp/bikegame-network-cache godot --headless --path game --script res://tests/network_loopback_smoke.gd

soak-check:
	@XDG_DATA_HOME=/tmp/bikegame-soak-data XDG_CONFIG_HOME=/tmp/bikegame-soak-config XDG_CACHE_HOME=/tmp/bikegame-soak-cache godot --headless --path game --script res://tests/street_life_soak.gd

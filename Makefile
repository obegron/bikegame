.PHONY: check benchmark audit-map network-check soak-check

AUDIT_LEVEL ?= monaco
AUDIT_OUTPUT ?= /tmp/bikegame-audit
AUDIT_FLAGS ?=

check:
	@./scripts/check_project.sh

benchmark:
	@godot --path game --script res://tests/level_performance_benchmark.gd $(BENCHMARK_FLAGS)

audit-map:
	@godot --headless --path game --script res://tools/world_audit.gd -- --level $(AUDIT_LEVEL) --output $(AUDIT_OUTPUT) $(AUDIT_FLAGS)

network-check:
	@XDG_DATA_HOME=/tmp/bikegame-network-data XDG_CONFIG_HOME=/tmp/bikegame-network-config XDG_CACHE_HOME=/tmp/bikegame-network-cache godot --headless --path game --script res://tests/network_loopback_smoke.gd

soak-check:
	@XDG_DATA_HOME=/tmp/bikegame-soak-data XDG_CONFIG_HOME=/tmp/bikegame-soak-config XDG_CACHE_HOME=/tmp/bikegame-soak-cache godot --headless --path game --script res://tests/street_life_soak.gd

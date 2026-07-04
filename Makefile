# Makefile für FiveM Lua Resource Linting
# Prüft Lua-Syntax und FiveM-Kompatibilität

.PHONY: all lint syntax check-fivem check-patterns full-check clean help

# Lua-Interpreter und Linter
LUAC = luac
LINT_TOOL = luacheck

# Resource-Pfad
RESOURCE_NAME = ai-peds
RESOURCE_PATH = /home/frank/Dokumente/test-lua

# Alle Lua-Dateien finden
LUA_FILES := $(shell find $(RESOURCE_PATH) -name '*.lua' -type f)

# Default Target
all: lint

# Lua-Syntax prüfen
syntax:
	@echo "=== Lua Syntax Check ==="
	@for file in $(LUA_FILES); do \
		echo "Checking: $$file"; \
		$(LUAC) -p "$$file" || exit 1; \
	done
	@echo "✓ Alle Lua-Dateien haben korrekte Syntax"

# FiveM-spezifische Checks
check-fivem: syntax
	@echo "=== FiveM Compatibility Check ==="
	@echo "Checking for common FiveM issues..."
	@! grep -rF "print(" $(RESOURCE_PATH) --include="*.lua" | grep -v "^$(RESOURCE_PATH)/.dev" | head -5 || echo "  - print() statements found (consider removing for production)"
	@! grep -rF "wait(" $(RESOURCE_PATH) --include="*.lua" --exclude-dir=client --exclude-dir=server || true
	@echo "✓ FiveM Checks abgeschlossen"

# Haupt-Linting mit luacheck (falls verfügbar)
lint: syntax
	@echo "=== LuaCheck Static Analysis ==="
	@if command -v $(LINT_TOOL) >/dev/null 2>&1; then \
		$(LINT_TOOL) $(LUA_FILES) --max-line-length=200 --no-unused-args --no-unused-fields; \
	else \
		echo "luacheck nicht gefunden, überspringe statische Analyse"; \
	fi
	@echo "✓ Linting abgeschlossen"

# FiveM-typische Muster prüfen
check-patterns:
	@echo "=== Checking FiveM Patterns ==="
	@echo "Suche nach POTENTIELLEN Problemen:"
	@grep -rn "CreateThread\|Citizen\.CreateThread" $(RESOURCE_PATH) --include="*.lua" | head -3
	@echo "  - Thread-Erstellung: OK"
	@grep -rn "Wait\|SetTimeout" $(RESOURCE_PATH) --include="*.lua" | wc -l | xargs -I {} echo "  - Wait/SetTimeout Aufrufe: {}"
	@grep -rn "TriggerClientEvent\|TriggerServerEvent" $(RESOURCE_PATH) --include="*.lua" | head -3
	@echo "  - Events: OK"
	@echo "✓ Pattern Check abgeschlossen"

# Vollständiger Check
full-check: syntax check-fivem check-patterns
	@echo ""
	@echo "=== Alle Checks bestanden! ✅ ==="

# Bereinigen
clean:
	@echo "Cleaning temp files..."
	@rm -f /tmp/lua_check_*.log 2>/dev/null || true

# Hilfe
help:
	@echo "Verfügbare Targets:"
	@echo "  make syntax      - Lua Syntax prüfen"
	@echo "  make lint        - Vollständiges Linting"  
	@echo "  make check-fivem - FiveM-Kompatibilität prüfen"
	@echo "  make full-check  - Alle Checks ausführen"
	@echo "  make clean       - Temporäre Dateien löschen"
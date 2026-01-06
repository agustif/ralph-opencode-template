run:
	./ralph.sh 50 prompt.md

test:
	@./ralph.sh run --test 1 prompt.md 2>/dev/null && echo "✓ Script runs"
	@bash -n ralph.sh && echo "✓ Syntax valid"
	@OVER_150=$$(find . -type f -name "*.sh" 2>/dev/null | xargs wc -l 2>/dev/null | awk '$$1>150 && $$2!="total" {print $$2" ("$$1" LOC)"}'); \
		[[ -z "$$OVER_150" ]] && echo "✓ All bash files under 150 LOC" || { echo "⚠ Bash files over 150 LOC - split into modules:"; echo "$$OVER_150"; exit 1; }

shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck ralph.sh install.sh convert_log.sh 2>/dev/null || shellcheck ralph.sh install.sh convert_log.sh; \
	else \
		echo "⚠ shellcheck not installed (optional dev tool)"; \
		echo "  Install: brew install shellcheck  # macOS"; \
		echo "  Install: apt-get install shellcheck  # Debian/Ubuntu"; \
	fi

lint: shellcheck test

clean:
	rm -f .ralph.log .ralph.log.jsonl .ralph.clean.log

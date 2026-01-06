run:
	./ralph.sh 50 prompt.md

test:
	@./ralph.sh --test 1 >/dev/null 2>&1 && echo "✓ Script runs" || { echo "✗ Script failed"; exit 1; }
	@bash -n ralph.sh && echo "✓ Syntax valid" || { echo "✗ Syntax error"; exit 1; }
	@bash -n install.sh && echo "✓ Install script syntax valid" || { echo "✗ Install script syntax error"; exit 1; }
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck ralph.sh install.sh && echo "✓ Shellcheck passed"; else echo "⚠ shellcheck not found"; fi

lint: test

clean:
	rm -f .ralph.log .ralph.log.jsonl .ralph.clean.log

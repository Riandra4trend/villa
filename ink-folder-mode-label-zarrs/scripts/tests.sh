#!/bin/bash
# The new regression test against main's inference code and against the fix, then the whole ink_detection suite.
# Usage: tests.sh <villa checkout with the fix> <villa checkout of main>
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
fix="$1/vesuvius"; main="$2/vesuvius"
python="$HOME/villa/vesuvius/.venv/bin/python"
tools="$(mktemp -d)"
uv pip install -q --target "$tools" pytest  # the built environment has no pytest; keep it out of the venv
cd "$fix"
test=tests/ink_detection/test_flat_inference.py::test_folder_mode_runs_a_segment_stored_beside_its_label_zarrs
echo "== new test, inference code of main ($(git -C "$main" log --oneline -1 | cut -c1-9))"
PYTHONPATH="$main/src:$tools" "$python" -m pytest -q -p no:cacheprovider "$test" 2>&1 | grep -E '^E  |passed|failed'
echo "== new test, this branch ($(git log --oneline -1 | cut -c1-9))"
PYTHONPATH="$fix/src:$tools" "$python" -m pytest -q -p no:cacheprovider "$test" 2>&1 | grep -E '^E  |passed|failed'
echo "== tests/ink_detection, this branch"
PYTHONPATH="$fix/src:$tools" "$python" -m pytest -q -p no:cacheprovider tests/ink_detection 2>&1 | grep -E 'passed|failed'
rm -rf "$tools"

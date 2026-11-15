#!/bin/bash
# Tutorial 5, "Setting up the pipeline": install uv, clone villa. (Shallow clone to save bandwidth.)
set -euo pipefail
curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
export PATH="$HOME/.local/bin:$PATH"
uv --version
git clone --quiet --depth 1 https://github.com/ScrollPrize/villa.git "$HOME/villa"
git -C "$HOME/villa" log -1 --format='villa HEAD: %H %cs'

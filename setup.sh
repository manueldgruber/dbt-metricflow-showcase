#!/usr/bin/env zsh
set -euo pipefail

# Install uv if not present
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"
fi

uv sync

# Inject DBT_PROFILES_DIR into the venv so it's set whenever the venv is active
echo "" >> .venv/bin/activate
echo "export DBT_PROFILES_DIR=\"$(pwd)\"" >> .venv/bin/activate

source .venv/bin/activate

uv run dbt deps
uv run dbt seed
uv run dbt build

echo ""
echo "Setup complete. Activate the venv and you're good to go:"
echo "  source .venv/bin/activate"
echo "  mf query --metrics total_revenue --group-by metric_time__month"

#!/usr/bin/env bash
# After apply: make sure the alacritty theme state file exists (it is generated,
# not managed) so the terminal never boots colorless on a fresh machine.
set -euo pipefail
"{{ .chezmoi.homeDir }}/.local/bin/theme" night >/dev/null 2>&1 || true

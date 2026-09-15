#!/usr/bin/env bash
# bootstrap.sh — provisioning de portátil de trabajo (CachyOS x86_64).
# Día D (repo aún privado):
#   sudo pacman -S --needed git gh chezmoi
#   gh auth login
#   git clone https://github.com/kcurtet/dotfiles.git ~/.local/share/chezmoi
#   ~/.local/share/chezmoi/bootstrap.sh && chezmoi apply
set -euo pipefail

say() { printf '\n▸ %s\n' "$*"; }

say "1/4 paquetes del sistema (pacman)"
sudo pacman -Sy --needed --noconfirm \
  git git-delta bat lazygit fzf zoxide eza gh alacritty \
  nodejs npm bun go rustup worktrunk docker

say "2/4 runtimes y herramientas externas"
[[ -x "$HOME/.local/bin/uv" ]] || curl -LsSf https://astral.sh/uv/install.sh | sh
[[ -x "$HOME/.cargo/bin/rustup" ]] || "$HOME/.cargo/bin/rustup" toolchain install stable --component rust-analyzer 2>/dev/null \
  || rustup toolchain install stable --component rust-analyzer
[[ -x "$HOME/.local/bin/herdr" ]] || curl -fsSL https://herdr.dev/install.sh | sh
[[ -x "$HOME/.local/bin/pi" ]] || npm install -g --ignore-scripts @earendil-works/pi-coding-agent

say "3/4 servicios"
sudo systemctl enable --now docker

say "4/4 pendiente manual (no automatizable)"
cat <<'EOF'
  - gh auth login                                  (si no lo hiciste ya)
  - ssh-keygen -t ed25519 -C "laptop"  + añadir la key a GitHub
  - primera sesión: herdr  (crea la sesión persistente)
  - toolkit python persistente:
      uv venv ~/.venvs/agent
      uv pip install --python ~/.venvs/agent numpy pillow opencv moviepy
  - crear ~/dev/nutux-labs (el launcher `p` lo usa como raíz de proyectos)
  - proyecto nvim: primer arranque de nvim instala los plugins (lazy.nvim)
EOF
echo -e "\n✓ bootstrap terminado — ahora: chezmoi apply"

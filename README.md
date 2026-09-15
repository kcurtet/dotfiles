# dotfiles

Provisioning de portátil de trabajo (CachyOS). Gestor: [chezmoi](https://www.chezmoi.io).

## Qué hay

| Área | Qué |
|---|---|
| **alacritty** | config + temas nord día/noche (`theme-nord{,-light}.toml`) |
| **theme** (`~/.local/bin/theme`) | conmutador día/noche: alacritty + herdr + pi + nvim + git-delta + bat |
| **nvim** | NvChad (base `NvChad/starter`) — autocmds sincronizan el tema nord al foco |
| **git** | delta como pager (features `night`/`day`), email noreply |
| **zsh** | launcher `p` (fzf → herdr workspace + pi), aliases `pc` `pl` `lg` `pq`, `cat`→bat |
| **bat, lazygit, herdr** | configs alineadas con la paleta nord |

Fuera a propósito: `~/.pi` (auth/sesiones privadas), `theme-current.toml` (estado generado).

## Día D (máquina nueva)

```bash
sudo pacman -S --needed git gh chezmoi
gh auth login                       # autoriza el clon del repo privado
git clone https://github.com/kcurtet/dotfiles.git ~/.local/share/chezmoi
~/.local/share/chezmoi/bootstrap.sh # paquetes + runtimes + herdr + pi
chezmoi apply                       # aplica configs y deja nord activo
```

Después, el checklist manual que imprime el bootstrap (ssh key, `herdr`, venv de agent, `~/dev/nutux-labs`).

## Uso diario

- Editar una config → `chezmoi edit <fichero>` (edita la fuente) → `chezmoi apply`
- Añadir una config nueva → `chezmoi add <fichero>`
- Ver qué cambiaría → `chezmoi diff`
- Sincronizar entre máquinas → `chezmoi update` (pull + apply)

## nvim

Incluido aquí (fue clon de `NvChad/starter`; sin repo propio). Primer arranque instala los plugins con `lazy.nvim`; `lazy-lock.json` fija versiones.

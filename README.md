# dotfiles

Config gestionada con [chezmoi](https://www.chezmoi.io).

Gestiona: **emacs** (`~/.emacs.d`: init, snippets, docs), **herdr** (keybinds) y **ghostty** (config + temas catppuccin).

**nvim** vive aparte en [kcurtet/nvim](https://github.com/kcurtet/nvim) (template de AstroNvim, se actualiza con `git pull upstream`).

## Máquina nueva

```sh
chezmoi init --apply git@github.com:kcurtet/dotfiles.git
```

## Flujo diario

Edita los ficheros en `~`, luego:

```sh
chezmoi re-add
git commit && git push
```

Commits firmados con PGP (`15C50965B97E1BEA`).

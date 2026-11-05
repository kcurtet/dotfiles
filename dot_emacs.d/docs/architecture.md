# Arquitectura & Políticas

## Estructura

```
~/.emacs.d/
├── early-init.el      # solo frame/UI y startup (package nil, native-comp warnings off)
├── init.el            # TODO el resto (~1100 líneas, monolítico intencional)
├── straight/          # paquetes + lockfile (straight/versions/default)
├── eln-cache/         # native-comp
├── recentf.eld, places.eld, undo-tree-history, tramp/  # estado persistido
└── AGENTS.md, docs/
```

Decisión: init único, no módulos en `lisp/`. Si init.el supera ~1500 líneas de forma estable, valorar split — no antes.

## Stack fijo (no cambiar salvo decisión explícita)

| Categoría | Elección | Alternativas descartadas |
|---|---|---|
| Gestión paquetes | straight.el | package.el, elpaca |
| Modal | evil + undo-tree | god-mode |
| Leader | general.el | which-key prefixes manuales |
| Completado minibuffer | vertico + orderless | ivy, helm, mct |
| Completado en buffer | corfu + cape | company |
| Buscar | consult + embark | counsel, swiper suelto |
| LSP | eglot | lsp-mode |
| Sintaxis | flycheck | flymake |
| Git | magit | |
| Mail | notmuch + smtpmail + pass | mu4e |
| Notas | denote | org-roam |
| Terminal | vterm | eshell como default shell |
| Tema | catppuccin macchiato | |

## Añadir un paquete

1. Bloque `use-package` en la sección temática correcta.
2. `:straight t`, defer máximo (`:commands`/`:bind`/`:hook`).
3. Keybinds nuevos → sub-líder existente o nuevo (ver `docs/keybindings.md`).
4. Al confirmar que funciona: lockfile actualizado (`straight-freeze-versions` o prompt de cierre). Commit si este repo se versiona.
5. Fork: `:straight (:host github :repo "...")` + freeze de la versión para evitar deriva.

## Quitar un paquete

Borrar bloque + `straight-remove-unused-repos` regenera. Revisar referencias en keybinds/hooks antes.

## Startup

- Presupuesto: < 1.5s. Medir con `use-package-compute-statistics` temporal o `emacs --batch -l init.el --eval '(message "%s" emacs-init-time)'`... simplemente `emacs-init-time` tras arranque real.
- gcmh gestiona GC post-init; durante init, GC off y restaurado en `after-init-hook`.

## Backups/estado

`make-backup-files nil`; auto-save en `auto-save-list/`; undo-tree persiste history en `undo-tree-history/`. No activar lockfiles nuevos sin razón.

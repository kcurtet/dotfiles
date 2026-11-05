# AGENTS.md — ~/.emacs.d

Config de Emacs personal. Un solo archivo monolítico: `init.el` (~1100 líneas) + `early-init.el` (17 líneas). Sin `custom.el`, sin carpetas de módulos.

## Gestión de paquetes

- **straight.el** (bootstrap en `init.el`, repos en `straight/repos/`, ~80 pkgs). `package.el` deshabilitado en `early-init.el` (`package-enable-at-startup nil`).
- `use-package` con `straight-use-package-by-default t` y `use-package-always-ensure t` (este último es irrelevante para straight; herencia de config antigua).
- Custom forks/recetas: `:straight (:host github :repo ...)` para ligature.el; varios `:straight nil` (paquetes built-in).
- Al añadir paquete: bloque `use-package` con `:straight t` (o nil si built-in) y `:defer`/`:commands` cuando pueda — el init ya usa defer agresivo (magit, treemacs, notmuch).

## Stack / filosofía

- **Evil** (undo-system `undo-tree`) + evil-collection, evil-surround, evil-commentary, evil-snipe.
- **general.el**: leader global `SPC` (`:states '(normal visual motion emacs)`, `:keymaps 'override`, non-normal-prefix `M-SPC`). `SPC` = `execute-extended-command` (M-x). Sub-líderes notables: `SPC n` denote, `SPC g` magit, `SPC t t` treemacs, `SPC F t` font transient.
- **Vertico + Orderless + Corfu + Cape + Marginalia + Consult + Embark + which-key** (completado/selectrum moderno; sin ivy/helm/company).
- **Eglot** (no lsp-mode) + flycheck (no flymake). tree-sitter + evil-textobj-tree-sitter + ligature.
- Lenguajes: rust-mode (format-on-save, rustfmt), cc-mode (tab 4), yaml (indent 2), markdown (+ mixed-pitch, olivetti, markdown-table-wrap, pilish).
- UI: tema **catppuccin macchiato**, doom-modeline, all-the-icons, rainbow-delimiters.
- Mail: **notmuch + smtpmail + pass** (Gmail kcurtet@gmail.com, drafts en `[Gmail]/Borradores`, FCC off). Keybinds custom en notmuch-show (`C-j`/`C-k` navegan hilos, override de evil-collection).
- Notas: **denote** (keybinds `SPC n`).
- Terminal: vterm. Git: magit (defer). Edición: multiple-cursors, expand-region, ws-butler, format-all, ace-window (`aw-keys` asdfghjkl).

## Convenciones del init

- `lexical-binding: t` en ambos archivos.
- Startup rápido: gc-cons-threshold max durante init (reset con gcmh), `file-name-handler-alist` nil durante init y restaurado después; native-comp warnings silenciados en `early-init.el`.
- Defaults: `tab-width 4`, `indent-tabs-mode nil` (algunos modos lo sobreescriben a 2: yaml), `make-backup-files nil`.
- Comentarios de sección con `;; ── Nombre ──`.
- Funciones propias prefijadas `my/`.

## Reglas para el agente

- Cambios en español OK (comentarios existentes mezclan es/en).
- **Nunca** migrar a package.el ni añadir `:ensure` sin straight.
- Probar tras editar: `emacs --batch -l init.el` o abrir Emacs; straight reinstall si un fork cambia (`straight-rebuild-package`).
- Versiones de forks fijas en `straight/versions/` (lockfile default) — no regenerarlo salvo intención.
- `early-init.el` solo para UI frame + startup: no cargar paquetes ahí.

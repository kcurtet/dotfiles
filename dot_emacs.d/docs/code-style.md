# Code Style (Elisp)

Reglas para escribir/editar código en `init.el` y `early-init.el`.

## Formato

- `;;; -*- lexical-binding: t; -*-` en la primera línea, siempre.
- Indent 4 espacios (tab-width 4), `indent-tabs-mode nil`. Re-indentar con `C-M-\` / `eglot-format`.
- Ancho máx ~100 columnas; listas largas de `setq`/keybinds alinean valores en columna (ver bloques `leader`).
- Una sentencia `setq` por variable cuando lleva comentario propio; agrupar variables relacionadas en un solo `setq` multilinea.

## Nombres

- Funciones/variables propias: prefijo `my/` (ej. `my/quit-frame`, `my/font-size-menu`). Nunca sin prefijo — contamina el espacio global.
- Modo menor hipotético propio: `my/-mode`.

## Estructura del init

- Un bloque `use-package` por paquete, orden temático: tema/UI → evil → general/keybinds → completado → lenguajes/LSP → git/proyecto → mail/notas → misc.
- Separadores de sección: `;; ── Nombre ──` (con los caracteres `─`).
- Comentarios: español o inglés, preferir español para explicaciones de intención; inglés para docstrings.

## use-package

- `:straight t` explícito salvo built-ins (`:straight nil`).
- Defer siempre que se pueda: `:commands`, `:bind`, `:mode`, `:hook` o `:defer N`. Nada eager salvo tema/modeline.
- `:init` para código pre-load (setq ligeros), `:config` para post-load, `:custom` no — usar `setq` en `:init`/`:config`.
- Hooks con nombre de función, no lambdas, si puede quererse quitar después (`add-hook 'mode #'fn :depth 0`).

## Antipatrones (prohibido)

- `require` de paquetes con defer (rompe el lazy-load).
- `eval-after-load` manual — usar `with-eval-after-load` o `:config`.
- Modificar `file-name-handler-alist`/GC fuera del bloque de startup.
- Keybinds globales con `define-key` suelto — todo va por `general` (leader o `general-define-key`).
- `(global-set-key [f1] ...)`: layout sin fn-keys; ver `docs/keybindings.md`.

## Verificación

Tras editar: `emacs --batch -l ~/.emacs.d/init.el` (debe salir sin errores) o abrir frame nuevo. Byte-compile opcional: `emacs --batch -f batch-byte-compile init.el` y revisar warnings.

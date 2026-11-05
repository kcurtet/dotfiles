# Keybindings & Conventions

## Leader

Definido con `general-create-definer leader`:

```elisp
:states '(normal visual motion emacs)
:keymaps 'override
:prefix "SPC"
:non-normal-prefix "M-SPC"
```

Reglas al añadir keybinds:

1. Todo va en el leader (o en `general-define-key` con `:states`). Nada por libre con `define-key` en mapas globales.
2. Grupos: primera tecla = mnemónico del grupo con `'(:ignore t :wk "nombre")`, segunda = acción. `"ff"` = files→find-file.
3. Siempre `:wk` (which-key description) en cada entrada.
4. Mayúscula = variante más fuerte/inversa (`fs` save, `fS` save-as; `wd` delete window, `wD` delete others; `qQ` vs `qq`).
5. Prefijos reservados actuales:
   - `f` files, `b` buffers, `w` windows, `s` search, `c` code, `C` compile, `g` git, `p` project, `t` toggles, `F` font, `h` help, `y` yank, `q` quit/session, `n` denote (definidos en su bloque).
6. Single-keys bajo SPC: `SPC`=M-x, `.`=find-file, `,`=consult-buffer, `` ` ``=eshell, `;`=comment, `u`/`U` undo tree.
7. No reasignar single-keys existentes; nuevo grupo antes que sobreescribir.

## Layout físico

- Teclado español, sin fn-keys, sin flechas — keybinds nuevos solo con letras/dígitos y modificadores estándar. Evitar `C-<parsing raro>` tipo `C-[`/`C-]`.
- Modos evil: keybinds de modo con `evil-define-key '(normal motion) mapa ...`.

## Notas por paquete

- notmuch: `C-j`/`C-k` en `notmuch-show-mode` navegan hilos; hay override local (`my/notmuch-show-override-keys`) porque evil-collection redefine el mapa auxiliar.
- `gd` en normal = xref-find-definitions con backup de punto.
- ace-window global en `M-o`, `aw-keys` = asdfghjkl.

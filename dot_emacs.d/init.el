;;; init.el --- Full programming Emacs configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;; The systemd user service starts the daemon before Plasma exports
;; session vars, so WAYLAND_DISPLAY/DISPLAY are missing from its
;; environment.  Without them `browse-url-can-use-xdg-open' returns nil
;; and browse-url falls back to firefox instead of the system default
;; browser via xdg-open.
(when (and (daemonp) (not (getenv "WAYLAND_DISPLAY")))
  (setenv "WAYLAND_DISPLAY" "wayland-0")
  (setenv "DISPLAY" ":0"))

;; ─────────────────────────────────────────────────────────
;; Startup speed: raise GC threshold + disable file-name-handler
;; only while init runs; restore afterwards (gcmh manages runtime).
;; ─────────────────────────────────────────────────────────
(setq gc-cons-threshold most-positive-fixnum
      gc-percentage 0.6)
(defvar my/--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist my/--file-name-handler-alist
                  gc-cons-threshold (* 64 1024 1024) ; gcmh-mode takes over
                  gc-percentage 0.1)))

(eval-when-compile
  (require 'cl-lib)
  (setq use-package-compute-statistics nil) ; Opcional: evita ruidos si usas estadísticas
  (setq use-package-always-ensure t))       ; Asegura que entienda que los paquetes se instalan

;; ─────────────────────────────────────────────────────────
;; Bootstrap: straight.el + use-package
;; ─────────────────────────────────────────────────────────
(defvar bootstrap-version)
(defvar straight-use-package-by-default nil)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq inhibit-splash-screen t)

(eval-when-compile
  (setq straight-use-package-by-default 't))

;; dape depende de una versión nueva de project (vía straight); cargarla
;; ANTES de que cualquier paquete cargue el project built-in, o Emacs 31
;; lanza "Feature 'project ... is now provided by" al duplicar.
(straight-use-package 'project)
(require 'project) ;; antes de add-hook: defvar no pisa valor ya existente

;; project.el no reconoce tsconfig.json/package.json como root;
;; eglot y dape se quedan sin proyecto en dirs sin .git (visto con ts-test)
(defun my/project-find-package (dir)
  "Proyecto transient con root en package.json/tsconfig.json más cercano."
  (when-let* ((root (cl-some (lambda (m) (locate-dominating-file dir m))
                              '("package.json" "tsconfig.json" "Cargo.toml"))))
    (cons 'transient root)))
(setq project-find-functions (list #'project-try-vc #'my/project-find-package))

;; ─────────────────────────────────────────────────────────
;; General Emacs defaults
;; ─────────────────────────────────────────────────────────
;; UI bars already disabled in early-init.el (faster, no resize flicker)
(blink-cursor-mode 0)
(setq-default tab-width 4
              indent-tabs-mode nil
              fill-column 100
              truncate-lines t
              word-wrap t)
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      ring-bell-function 'ignore
      echo-keystrokes 0.02
      compile-command "make -k ")

(save-place-mode 1)                      ;; remember cursor position
(show-paren-mode 1)                       ;; highlight matching parens
(electric-pair-mode 1)                    ;; auto-insert pairs
(global-hl-line-mode 1)                   ;; highlight current line
(column-number-mode 1)                    ;; show column in modeline
(global-display-line-numbers-mode 1)      ;; line numbers everywhere
(dolist (hook '(term-mode-hook
                vterm-mode-hook
                eshell-mode-hook
                shell-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode 0))))

;; ─────────────────────────────────────────────────────────
;; Theme & Modeline
;; ─────────────────────────────────────────────────────────
(use-package catppuccin-theme
  :init
  (defvar catppuccin-flavor nil)
  (setq catppuccin-flavor 'macchiato)
  (load-theme 'catppuccin :no-confirm))

(use-package all-the-icons
  :if (display-graphic-p)
  :custom
  (inhibit-compacting-font-caches t))

(use-package all-the-icons-dired
  :after all-the-icons
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; ─────────────────────────────────────────────────────────
;; Undo: undo-tree (replaces undo-fu)
;; ─────────────────────────────────────────────────────────
(use-package undo-tree
  :diminish undo-tree-mode
  :init
  (global-undo-tree-mode)
  :custom
  (undo-tree-visualizer-diff t)          ;; show diff in visualizer
  (undo-tree-visualizer-timestamps t)
  (undo-tree-enable-undo-in-region nil)  ;; safer; region undo can corrupt
  (undo-tree-history-directory-alist `(("." . ,(expand-file-name "undo-tree-history" user-emacs-directory))))
  :bind (:map undo-tree-visualizer-mode-map
              ("<down>" . undo-tree-visualizer-redo)
              ("<up>"   . undo-tree-visualizer-undo)
              ("q"      . undo-tree-visualizer-quit)))

;; ─────────────────────────────────────────────────────────
;; Evil (with undo-tree)
;; ─────────────────────────────────────────────────────────
(use-package evil
  :init
  (setq evil-undo-system 'undo-tree
        evil-want-keybinding nil     ;; needed for evil-collection
        evil-want-integration t
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-shift-width 4
        evil-cross-lines t)
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

(use-package evil-commentary
  :after evil
  :diminish evil-commentary-mode
  :config (evil-commentary-mode))

(use-package evil-snipe
  :after evil
  :diminish evil-snipe-mode
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1))

;; ─────────────────────────────────────────────────────────
(defun my/daemon--confirm (verb save-buffers)
  "Y-or-n prompt for a daemon operation; save buffers when asked."
  (when (y-or-n-p
         (if save-buffers
             (format "¿%s el daemon de Emacs? (guarda buffers) " verb)
           (format "¿%s el daemon SIN guardar buffers? " verb)))
    (when save-buffers (save-some-buffers t))
    t))

(defun my/kill-daemon--core (save-buffers)
  "Kill this Emacs process (works for manual or systemd daemons)."
  (when (my/daemon--confirm "Apagar" save-buffers)
    (kill-emacs)))

(defun my/kill-daemon-save ()
  "Shut down the Emacs daemon, saving buffers first."
  (interactive)
  (my/kill-daemon--core t))

(defun my/kill-daemon-no-save ()
  "Shut down the Emacs daemon WITHOUT saving buffers."
  (interactive)
  (my/kill-daemon--core nil))

(defun my/quit-frame ()
  "Close the current frame (window); daemon and buffers stay alive.
Standalone (non-daemon) sessions fall back to save-and-kill."
  (interactive)
  (if (daemonp)
      (delete-frame)
    (save-buffers-kill-terminal)))

;; Leader keybindings via general.el
;; ─────────────────────────────────────────────────────────
(use-package general
  :config
  (general-evil-setup t)

  ;; ── Global leader (SPC) ──
  (general-create-definer leader
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  (leader
    "" nil  ;; clear prefix

    ;; ── Files ──
    "f"   '(:ignore t :wk "files")
    "ff"  '(find-file :wk "find file")
    "fr"  '(consult-recent-file :wk "recent files")
    "fs"  '(save-buffer :wk "save")
    "fS"  '(write-file :wk "save as")
    "fd"  '(dired-jump :wk "dired")

    ;; ── Buffers ──
    "b"   '(:ignore t :wk "buffers")
    "bb"  '(consult-buffer :wk "switch buffer")
    "bs"  '(save-buffer :wk "save")
    "bS"  '(save-some-buffers :wk "save all")
    "bk"  '(kill-this-buffer :wk "kill buffer")
    "bn"  '(next-buffer :wk "next buffer")
    "bp"  '(previous-buffer :wk "prev buffer")
    "br"  '(revert-buffer :wk "revert")
    "bi"  '(ibuffer :wk "ibuffer")

    ;; ── Windows ──
    "w"   '(:ignore t :wk "windows")
    "ws"  '(split-window-below :wk "split below")
    "wv"  '(split-window-right :wk "split right")
    "wd"  '(delete-window :wk "delete window")
    "wD"  '(delete-other-windows :wk "delete others")
    "wh"  '(evil-window-left :wk "focus left")
    "wj"  '(evil-window-down :wk "focus down")
    "wk"  '(evil-window-up :wk "focus up")
    "wl"  '(evil-window-right :wk "focus right")
    "wo"  '(ace-window :wk "ace window (M-o)")
    "wu"  '(winner-undo :wk "undo layout")
    "wU"  '(winner-redo :wk "redo layout")
    "w="  '(balance-windows :wk "balance")
    "wm"  '(maximize-window :wk "maximize")

    ;; ── Search ──
    "s"   '(:ignore t :wk "search")
    "ss"  '(consult-line :wk "line")
    "sS"  '(consult-line-multi :wk "line multi")
    "sg"  '(consult-ripgrep :wk "ripgrep")
    "sG"  '(consult-grep :wk "grep")
    "sf"  '(consult-find :wk "find file")
    "sr"  '(consult-register-load :wk "register")
    "sm"  '(consult-mark :wk "mark")
    "sk"  '(consult-keep-lines :wk "keep lines")
    "so"  '(consult-outline :wk "outline")

    ;; ── Code / Navigation ──
    "c"   '(:ignore t :wk "code")
    "cd"  '(xref-find-definitions :wk "go to definition")
    "cD"  '(xref-find-references :wk "find references")
    "cr"  '(xref-go-back :wk "go back")
    "cR"  '(xref-go-forward :wk "go forward")
    "ca"  '(eglot-code-actions :wk "code actions")
    "cf"  '(eglot-format :wk "format")
    "cF"  '(format-all-buffer :wk "format-all")
    "cn"  '(flycheck-next-error :wk "next error")
    "cp"  '(flycheck-previous-error :wk "prev error")
    "cl"  '(flycheck-list-errors :wk "list errors")
    "ch"  '(eldoc-doc-buffer :wk "hover doc")
    "ci"  '(consult-imenu :wk "imenu")
    "cI"  '(consult-imenu-multi :wk "imenu multi")
    "ce"  '(consult-compile-error :wk "compile errors")

    ;; ── Compile / Run ──
    "C"   '(:ignore t :wk "compile")
    "Cc"  '(compile :wk "compile")
    "Cr"  '(recompile :wk "recompile")
    "Ck"  '(kill-compilation :wk "kill compile")

    ;; ── Git ──
    "g"   '(:ignore t :wk "git")
    "gg"  '(magit-status :wk "magit")
    "gb"  '(magit-blame :wk "blame")
    "gd"  '(magit-diff-buffer-file :wk "diff file")
    "gl"  '(magit-log-buffer-file :wk "log file")
    "gL"  '(magit-log :wk "log repo")
    "gs"  '(magit-stage-file :wk "stage file")
    "gS"  '(magit-unstage-file :wk "unstage file")
    "gR"  '(vc-revert :wk "vc revert")

    ;; ── Project ──
    "p"   '(:ignore t :wk "project")
    "pp"  '(project-switch-project :wk "switch project")
    "pf"  '(project-find-file :wk "find file")
    "pg"  '(project-find-regexp :wk "find regexp")
    "pb"  '(consult-project-buffer :wk "project buffers")
    "pk"  '(project-kill-buffers :wk "kill project buffers")
    "pc"  '(project-compile :wk "project compile")
    "pd"  '(project-dired :wk "project dired")
    "pe"  '(project-eshell :wk "project eshell")
    "pm"  '(my/npm-run :wk "npm run <script>")
    "pt"  '(my/test-project :wk "run tests (vitest/jest)")
    "pT"  '(my/test-file :wk "run tests: este archivo")

    ;; ── Toggles ──
    "t"   '(:ignore t :wk "toggle")
    "tn"  '(display-line-numbers-mode :wk "line numbers")

    ;; ── Font ──
    "F"   '(:ignore t :wk "font")
    "Ft"  '(my/font-size-menu :wk "size menu (transient)")
    "F="  '(my/font-size-increase :wk "bigger")
    "F-"  '(my/font-size-decrease :wk "smaller")
    "F0"  '(my/font-size-reset :wk "reset")
    "tw"  '(visual-line-mode :wk "word wrap")
    "th"  '(global-hl-line-mode :wk "hl line")
    "tt"  '(treemacs :wk "treemacs")
    "tv"  '(undo-tree-visualize :wk "undo tree")

    ;; ── Help ──
    "h"   '(:ignore t :wk "help")
    "hf"  '(helpful-callable :wk "function")
    "hv"  '(helpful-variable :wk "variable")
    "hk"  '(helpful-key :wk "key")
    "hm"  '(describe-mode :wk "mode")
    "ht"  '(consult-theme :wk "theme")
    "hs"  '(helpful-symbol :wk "symbol")
    "hp"  '(describe-package :wk "package")

    ;; ── Insert / Yank ──
    "y"   '(:ignore t :wk "yank")
    "yy"  '(consult-yank-pop :wk "yank pop")

    ;; ── Quit / Session ──
    "q"   '(:ignore t :wk "quit/session")
    "qq"  '(my/quit-frame :wk "close window")
    "qQ"  '(my/kill-daemon-save :wk "stop daemon (save)")
    "qk"  '(my/kill-daemon-no-save :wk "stop daemon (no save)")

    ;; ── Misc ──
    "SPC"  '(execute-extended-command :wk "M-x")
    "u"    '(undo-tree-visualize :wk "undo tree")
    "U"    '(undo-tree-redo :wk "redo")
    "."    '(find-file :wk "find file")
    ","    '(consult-buffer :wk "buffers")
    "`"    '(eshell :wk "eshell")
    ";"    '(comment-line :wk "comment line")
    )

  ;; ── Go-to-definition with point backup (gd in normal state) ──
  (general-define-key
   :states 'normal
   "gd"  'xref-find-definitions
   "gD"  'xref-find-references
   "gr"  'xref-go-back
   "gR"  'xref-go-forward
   "K"   'eldoc-doc-buffer
   "gcc" 'comment-line
   "g["  'flycheck-previous-error
   "g]"  'flycheck-next-error))

;; ─────────────────────────────────────────────────────────
;; Completion: Vertico + Corfu + Cape + Orderless + Marginalia
;; ─────────────────────────────────────────────────────────
(use-package vertico
  :demand t
  :custom (vertico-cycle t)
  :bind (:map vertico-map
              ("M-j" . vertico-next)
              ("M-k" . vertico-previous)
              ("M-q" . abort-recursive-edit))
  :config (vertico-mode t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic substring initials))
  (completion-category-overrides '((file (styles basic partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-trigger ".")
  (corfu-quit-no-match 'separator)
  :init (global-corfu-mode)
  :bind (:map corfu-map
              ("TAB"     . corfu-next)
              ([tab]     . corfu-next)
              ("S-TAB"   . corfu-previous)
              ([backtab] . corfu-previous)
              ("RET"     . corfu-insert)
              ("M-RET"   . corfu-insert)      ;; prevent newline in terminals
              ("M-d"     . corfu-show-documentation)
              ("M-."     . corfu-show-location)))


(use-package cape
  :bind ("C-c p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

(use-package dabbrev
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  (add-to-list 'dabbrev-ignored-buffer-modes 'authinfo-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))

(use-package marginalia
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

;; ─────────────────────────────────────────────────────────
;; Consult + Embark
;; ─────────────────────────────────────────────────────────
(use-package consult
  :bind (;; C-c bindings
         ("C-c M-x" . consult-mode-command)
         ("C-c h"   . consult-history)
         ("C-c k"   . consult-kmacro)
         ("C-c m"   . consult-man)
         ("C-c i"   . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings
         ("C-x M-:" . consult-complex-command)
         ("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("C-x t b" . consult-buffer-other-tab)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ;; Registers
         ("M-#"   . consult-register-load)
         ("M-'"   . consult-register-store)
         ("C-M-#" . consult-register)
         ;; Yank
         ("M-y" . consult-yank-pop)
         ;; Goto
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; Search
         ("M-s d" . consult-find)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e"   . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         :map minibuffer-local-map
         ("M-s" . consult-history)
         ("M-r" . consult-history))
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<"))

(use-package embark
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings))
  :init (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package which-key
  :diminish which-key-mode
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.4
        which-key-sort-order 'which-key-key-order-alpha))

(use-package helpful
  :commands (helpful-callable helpful-variable helpful-key helpful-symbol))

;; ─────────────────────────────────────────────────────────
;; Windows & buffer display
;; ─────────────────────────────────────────────────────────

;; winner: undo/redo window-layout changes (C-c <left> / C-c <right>)
(winner-mode 1)

;; ace-window: jump between windows by home-row letter (M-o)
(use-package ace-window
  :init (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :bind ("M-o" . ace-window))

;; Where new buffers open: ephemeral output gets a dedicated slot at
;; the bottom; source files always reuse the current window.
(dolist (rule '(;; compile / diagnostics / xref / grep output
                ("\\`\\*\\(Compile-Log\\|compilation\\|Flymake.*\\|eglot-\\(events\\|stderr\\)\\|xref\\|Occur\\|grep\\|ripgrep\\)\\*"
                 (display-buffer-reuse-window display-buffer-in-direction)
                 (direction . bottom) (window-height . 0.25)
                 (dedicated . t))
                ;; help / documentation
                ("\\`\\*\\(Help\\|helpful.*\\|info\\|Man.*\\)\\*"
                 (display-buffer-reuse-window display-buffer-below-selected)
                 (window-height . 0.35)
                 (dedicated . t))
                ;; terminals / shells
                ("\\`\\*\\(vterm\\|eshell\\|shell\\|term\\)"
                 (display-buffer-reuse-window display-buffer-in-direction)
                 (direction . bottom) (window-height . 0.35)
                 (dedicated . t))))
  (add-to-list 'display-buffer-alist rule))

;; Debugging: dape (DAP) + vscode-js-debug — JS/TS/Node/Next.js
;; Next.js dev: `NODE_OPTIONS=--inspect npm run dev` y SPC d a (attach 9229)
;; Update adapter: tarball de https://github.com/microsoft/vscode-js-debug/releases
;;   curl -L <tarball-url> | tar -xz -C ~/.emacs.d/debug-adapters/js-debug --strip-components=1
;; ─────────────────────────────────────────────────────────
(use-package dape
  :straight t
  :config
  ;; js-debug (dapDebugServer) escucha SOLO en ::1; dape conecta a
  ;; "localhost" (127.0.0.1) y falla. Forzar host ::1 en configs js-debug.
  (dolist (cfg dape-configs)
    (when (and (memq (car cfg)
                     '(js-debug-node js-debug-ts-node js-debug-tsx
                       js-debug-node-attach js-debug-chrome))
               (not (plist-get (cdr cfg) 'host)))
      (setcdr cfg (plist-put (cdr cfg) 'host "::1"))))
  ;; dape trae configs js-debug-node/-attach/-chrome listas;
  ;; añado attach y launch para Next.js con skipFiles
  (dolist (cfg `((nextjs-attach
                  modes (js-ts-mode js-mode typescript-ts-mode tsx-ts-mode)
                  host "::1"
                  command "node"
                  command-args (,(expand-file-name
                                  "~/.emacs.d/debug-adapters/js-debug/src/dapDebugServer.js")
                                 :autoport)
                  port :autoport
                  :type "pwa-node"
                  :request "attach"
                  :port 9229
                  :cwd "${workspaceFolder}"
                  :sourceMaps t
                  :skipFiles ["<node_internals>/**" "**/node_modules/**"])
                 (nextjs-launch
                  modes (js-ts-mode js-mode typescript-ts-mode tsx-ts-mode)
                  host "::1"
                  command "node"
                  command-args (,(expand-file-name
                                  "~/.emacs.d/debug-adapters/js-debug/src/dapDebugServer.js")
                                 :autoport)
                  port :autoport
                  :type "pwa-node"
                  :request "launch"
                  :runtimeExecutable "npm"
                  :runtimeArgs ["run" "dev"]
                  :cwd "${workspaceFolder}"
                  :sourceMaps t
                  :console "integratedTerminal"
                  :skipFiles ["<node_internals>/**" "**/node_modules/**"])))
    (add-to-list 'dape-configs cfg))
  (setq dape-info-hide-mode-line nil
        dape-buffer-window-arrangement 'right))

(defun my/dape-config (name)
  "Lanza dape con la config NAME sin pedir."
  (dape (dape--config-eval (intern-soft name) nil)))

(defalias 'my/dape-attach-9229 (lambda () (interactive) (my/dape-config "nextjs-attach")))
(defalias 'my/dape-launch-nextjs (lambda () (interactive) (my/dape-config "nextjs-launch")))

;; ─────────────────────────────────────────────────────────
;; npm / tests / .env
;; ─────────────────────────────────────────────────────────
(defun my/project-package-json ()
  "Path del package.json del proyecto actual, o nil."
  (when-let* ((proj (project-current)))
    (let ((f (expand-file-name "package.json" (project-root proj))))
      (and (file-exists-p f) f))))

(defun my/npm-scripts ()
  "Alist (nombre . comando) de los scripts del package.json actual."
  (when-let* ((pkg (my/project-package-json)))
    (let ((json-object-type 'alist))
      (condition-case nil
          (cdr (assq 'scripts (json-read-file pkg)))
        (error nil)))))

(defun my/detect-test-runner ()
  "vitest, jest o nil según devDependencies del proyecto."
  (when-let* ((pkg (my/project-package-json)))
    (let ((json-object-type 'alist))
      (condition-case nil
          (let* ((json (json-read-file pkg))
                 (dev (cdr (assq 'devDependencies json)))
                 (deps (cdr (assq 'dependencies json))))
            (cond ((or (assq 'vitest dev) (assq 'vitest deps)) 'vitest)
                  ((or (assq 'jest dev) (assq 'jest deps)) 'jest)
                  ((assq 'next dev) nil) ;; next test
                  (t nil)))
        (error nil)))))

(defun my/test-project ()
  "Corre la suite de tests del proyecto (vitest/jest) vía compile."
  (interactive)
  (if-let* ((runner (my/detect-test-runner)))
      (let ((default-directory (project-root (project-current))))
        (compile (format "npx %s run" runner)))
    (user-error "No detecté vitest/jest en package.json")))

(defun my/test-file ()
  "Corre tests del archivo actual (vitest/jest) vía compile."
  (interactive)
  (if-let* ((runner (my/detect-test-runner)))
      (let* ((proj (project-current))
             (default-directory (project-root proj))
             (rel (file-relative-name (buffer-file-name) default-directory)))
        (compile (format "npx %s run %s" runner rel)))
    (user-error "No detecté vitest/jest en package.json")))

(defun my/npm-run (script)
  "npm run SCRIPT del proyecto (completa con los scripts disponibles)."
  (interactive
   (list (if-let* ((scripts (my/npm-scripts)))
             (completing-read "npm run: "
                              (mapcar (lambda (s) (symbol-name (car s))) scripts)
                              nil t)
           (read-string "npm run: "))))
  (let ((default-directory (project-root (project-current))))
    (compile (format "npm run %s" script))))

;; ── .env: cargar variables del proyecto en process-environment ──
;; (eglot, compile y dape heredan). Auto al abrir archivo de un proyecto.
(defvar my/dotenv-loaded-roots (make-hash-table :test #'equal)
  "Roots cuyo .env ya se cargó en esta sesión.")

(defun my/dotenv-load-project (&optional force)
  "Carga .env/.env.local/.env.development(.local) del proyecto actual.
Ya cargados se saltan salvo FORCE. Devuelve nº de vars nuevas."
  (interactive "P")
  (when-let* ((proj (project-current))
              (root (project-root proj))
              (_ (or force (not (gethash root my/dotenv-loaded-roots)))))
    (let ((count 0))
      (dolist (f '(".env" ".env.development" ".env.local"
                   ".env.development.local"))
        (let ((path (expand-file-name f root)))
          (when (file-exists-p path)
            (with-temp-buffer
              (insert-file-contents path)
              (dolist (line (split-string (buffer-string) "\n" t "\s-*"))
                (when (string-match "^\\(?:export \\)?\\([^=#]+\\)=\\(.*\\)$" line)
                  (let* ((k (string-trim (match-string 1 line)))
                         (v (string-trim (match-string 2 line)))
                         (v (string-remove-prefix "\"" (string-remove-suffix "\"" v))))
                    (setenv k v)
                    (cl-incf count))))))))
      (puthash root t my/dotenv-loaded-roots)
      (when (called-interactively-p 'any)
        (message ".env: %d vars cargadas de %s" count root))
      count)))

(defun my/dotenv-load-hook ()
  "Carga .env del proyecto al abrir un archivo (una vez por root)."
  (my/dotenv-load-project))

(add-hook 'find-file-hook #'my/dotenv-load-hook)

;; ─────────────────────────────────────────────────────────
;; Snippets (yas): propios en ~/.emacs.d/snippets/<modo>/
;; ─────────────────────────────────────────────────────────
(use-package yasnippet
  :straight t
  :diminish yas-minor-mode
  :hook (prog-mode . yas-minor-mode)
  :config
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  (yas-reload-all))

;; ─────────────────────────────────────────────────────────
;; diff-hl: cambios git en fringe
;; ─────────────────────────────────────────────────────────
(use-package diff-hl
  :straight t
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init (global-diff-hl-mode 1)
  :config (diff-hl-flydiff-mode 1))

(leader
  "d"  '(:ignore t :wk "debug")
  "dd" '(dape :wk "debug (elige config)")
  "da" '(my/dape-attach-9229 :wk "attach 9229 (Next.js dev)")
  "dl" '(my/dape-launch-nextjs :wk "launch npm run dev")
  "db" '(dape-breakpoint-toggle :wk "breakpoint")
  "dB" '(dape-breakpoint-remove-all :wk "rm all breakpoints")
  "dc" '(dape-continue :wk "continue")
  "dn" '(dape-next :wk "next")
  "ds" '(dape-step-in :wk "step in")
  "do" '(dape-step-out :wk "step out")
  "dr" '(dape-restart :wk "restart")
  "dk" '(dape-kill :wk "kill session")
  "de" '(dape-evaluate-expression :wk "eval expression")
  "dw" '(dape-watch-dwim :wk "watch expression"))

;; ─────────────────────────────────────────────────────────
;; LSP: eglot (built into Emacs 29+)
;; ─────────────────────────────────────────────────────────
(use-package eglot
  :hook
  ((c-mode c-ts-mode)   . eglot-ensure)
  ((rust-mode rust-ts-mode) . eglot-ensure)
  ((emacs-lisp-mode)    . eglot-ensure)
  (yaml-mode            . eglot-ensure)
  ((typescript-ts-mode tsx-ts-mode js-ts-mode) . eglot-ensure)
  :config
  (setq eglot-autoshutdown t
        eglot-confirm-server-initiated-edits nil
        eglot-sync-connect 1
        eldoc-documentation-strategy 'eldoc-documentation-compose)

  ;; Let eglot manage formatting via format-all or its own
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode) . ("clangd")))
  (add-to-list 'eglot-server-programs
               '((rust-mode rust-ts-mode) . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((typescript-ts-mode tsx-ts-mode js-ts-mode js-mode typescript-mode)
                 . ("typescript-language-server" "--stdio")))
  ;; Tailwind: server para css (en tsx no puede haber 2 servers con eglot;
  ;; para clases en tsx usar snippets tw-*)
  (add-to-list 'eglot-server-programs
               '((css-ts-mode css-mode) . ("tailwindcss-language-server" "--stdio")))

  ;; Silence the occasional "connected" messages spamming the echo area
  (fset #'jsonrpc--log-event #'ignore))

;; ─────────────────────────────────────────────────────────
;; Flycheck: on-the-fly diagnostics
;; ─────────────────────────────────────────────────────────
(use-package flycheck
  :diminish flycheck-mode
  :init (global-flycheck-mode)
  :config
  ;; lisp-interaction (*scratch*): sin checker aplicable tras desactivar checkdoc
  (setq flycheck-global-modes '(not lisp-interaction-mode))
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc))
  (setq flycheck-check-syntax-automatically '(save idle-change mode-enabled)
        flycheck-idle-change-delay 0.5
        flycheck-display-errors-delay 0.3)
  ;; ESLint en TS/TSX/JS si el proyecto tiene config de eslint
  (dolist (mode '(typescript-ts-mode-hook tsx-ts-mode-hook js-ts-mode-hook))
    (add-hook mode
              (lambda ()
                (when (and (executable-find "eslint")
                           (my/project-has-eslint-p))
                  (flycheck-mode 1)
                  (flycheck-select-checker 'javascript-eslint))))))

(defun my/project-has-eslint-p ()
  "Non-nil si el proyecto tiene .eslintrc* o eslint.config.*"
  (when-let* ((proj (project-current))
              (root (project-root proj)))
    (cl-some (lambda (f) (file-exists-p (expand-file-name f root)))
             '(".eslintrc" ".eslintrc.js" ".eslintrc.json"
               ".eslintrc.cjs" ".eslintrc.yml" "eslint.config.js"
               "eslint.config.mjs"))))

;; ─────────────────────────────────────────────────────────
;; C / C++ configuration
;; ─────────────────────────────────────────────────────────
(use-package cc-mode
  :ensure nil ;; built-in
  :hook ((c-mode c-ts-mode) . (lambda ()
                                (setq-local tab-width 4)
                                (setq-local c-basic-offset 4)
                                (c-set-style "linux")))
  :config
  (c-set-offset 'case-label '+))

;; ─────────────────────────────────────────────────────────
;; Rust configuration
;; ─────────────────────────────────────────────────────────
(use-package rust-mode
  :hook (rust-mode . (lambda ()
                       (setq-local tab-width 4)
                       (setq-local indent-tabs-mode nil)
                       (setq-local rust-format-on-save t)))
  :config
  (setq rust-format-show-buffer nil))

;; ─────────────────────────────────────────────────────────
;; TypeScript / JavaScript (modos-ts built-in Emacs 29+: ts, tsx, js, jsx)
;; LSP: typescript-language-server · Formato: prettier vía format-all
;; ─────────────────────────────────────────────────────────
(use-package typescript
  :straight nil :ensure nil
  :mode (("\\.ts\\'" . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cts\\'" . typescript-ts-mode)
         ("\\.tsx\\'" . tsx-ts-mode)
         ("\\.js\\'"  . js-ts-mode)
         ("\\.mjs\\'" . js-ts-mode)
         ("\\.cjs\\'" . js-ts-mode)
         ("\\.jsx\\'" . tsx-ts-mode))
  :hook ((typescript-ts-mode tsx-ts-mode js-ts-mode) .
         (lambda ()
           (setq-local tab-width 2)
           (setq-local indent-tabs-mode nil)
           (setq-local typescript-indent-offset 2)
           (setq-local js-indent-level 2)
           ;; tsserver como proyecto raíz: jsconfig/tsconfig no obligatorio
           (setq-local eglot-workspace-configuration
                       '(:javascript (:format (:semicolons "insert")
                                    :preferences (:quotePreference "single")))))))

;; JSON (json-ts-mode built-in) con indent 2
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-ts-mode))
(add-hook 'json-ts-mode-hook
          (lambda ()
            (setq-local tab-width 2
                        indent-tabs-mode nil
                        js-indent-level 2)))

;; ─────────────────────────────────────────────────────────
;; YAML
;; ─────────────────────────────────────────────────────────
(use-package yaml-mode
  :mode "\\.ya?ml\\'"
  :config
  (setq yaml-indent-offset 2)
  ;; yamllint validation via flycheck (already in PATH)
  (add-hook 'yaml-mode-hook
            (lambda ()
              (setq-local tab-width 2)
              (setq-local indent-tabs-mode nil))))

;; ─────────────────────────────────────────────────────────
;; Lua: lua-ts-mode (built-in) + lua-language-server (sumneko) + stylua
;; ─────────────────────────────────────────────────────────
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-ts-mode))
(add-hook 'lua-ts-mode-hook 'eglot-ensure)
(add-hook 'lua-ts-mode-hook
          (lambda ()
            (setq-local tab-width 2
                        indent-tabs-mode nil)))
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((lua-mode lua-ts-mode) . ("lua-language-server"))))

;; ─────────────────────────────────────────────────────────
;; Markdown: GFM, mixed-pitch, olivetti, tablas pretty, preview pandoc
;; Preview: C-c C-c p (navegador) · Tablas raw↔pretty: M-x markdown-table-wrap-pretty-toggle
;; ─────────────────────────────────────────────────────────
(use-package markdown-mode
  :mode (("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode))
  :custom
  (markdown-command '("pandoc" "--from=gfm" "--to=html5"
                      "--standalone" "--embed-resources"
                      "--css=/home/kx/.emacs.d/markdown-preview.css"
                      "--metadata=pagetitle=Preview"))
  (markdown-header-scaling t)
  (markdown-list-item-bullets '("▸" "◦" "✦"))
  (markdown-fontify-code-blocks-natively t)
  :hook ((markdown-mode . visual-line-mode)))

(use-package markdown-mermaid
  ;; :ensure (markdown-mermaid :type git :host github :repo "pasunboneleve/markdown-mermaid")
  :bind (:map markdown-mode-map
              ("C-c m" . markdown-mermaid-preview)))

(use-package mixed-pitch
  :commands (mixed-pitch-mode)   ; defer: only config vars here
  :config
  ;; Prose proportional; code, tables, markup and URLs stay mono
  (setq mixed-pitch-fixed-pitch-faces
        (append '(markdown-code-face markdown-inline-code-face
                  markdown-pre-face markdown-language-keyword-face
                  markdown-markup-face markdown-table-face markdown-url-face
                  markdown-metadata-key-face markdown-metadata-value-face
                  font-lock-comment-face font-lock-comment-delimiter-face
                  font-lock-doc-face font-lock-doc-markup-face
                  font-lock-keyword-face font-lock-string-face
                  font-lock-escape-face font-lock-function-name-face
                  font-lock-variable-name-face font-lock-type-face
                  font-lock-constant-face font-lock-builtin-face
                  font-lock-negation-char-face font-lock-preprocessor-face
                  font-lock-regexp-grouping-backslash
                  font-lock-regexp-grouping-construct)
                mixed-pitch-fixed-pitch-faces)))

(use-package olivetti
  :hook (markdown-mode . olivetti-mode)
  :custom (olivetti-body-width 100))

(use-package markdown-table-wrap
  :hook (markdown-mode . markdown-table-wrap-pretty-mode)
  :custom
  (markdown-table-wrap-pretty-default-on-major-modes '(gfm-mode markdown-mode)))

;; ─────────────────────────────────────────────────────────
;; Pilish: Emacs frontend for the pi coding agent (pi.dev)
;; Chat = markdown arriba, prompt = buffer normal abajo.
;; `M-x pi' o `M-x pilish'. Evil integration auto (pilish-evil).
;; Gramáticas tree-sitter: M-x pilish-install-grammars (una vez).
;; ─────────────────────────────────────────────────────────
(use-package pilish
  :commands (pilish)
  :init (defalias 'pi 'pilish))

;; ─────────────────────────────────────────────────────────
;; Magit
;; ─────────────────────────────────────────────────────────
(use-package magit
  ;; Defer: loads on first Magit command (SPC g)
  :commands (magit-status magit-blame magit-diff-buffer-file
             magit-log-buffer-file magit-log magit-stage-file magit-unstage-file))

;; ─────────────────────────────────────────────────────────
;; Multiple Cursors
;; ─────────────────────────────────────────────────────────
(use-package multiple-cursors
  ;; :bind defers loading until first use
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)))

;; ─────────────────────────────────────────────────────────
;; Formatting
;; ─────────────────────────────────────────────────────────
(use-package format-all
  :commands format-all-mode
  :diminish format-all-mode
  :hook (prog-mode . format-all-mode)
  :config
  (setq-default format-all-formatters
                '(("C"     (clang-format))
                  ("C++"   (clang-format))
                  ("Shell" (shfmt "-i" "4" "-ci"))
                  ("Rust"  (rustfmt))
                  ("YAML"  (prettier))
                  ("TypeScript" (prettier))
                  ("TSX"   (prettier))
                  ("JavaScript" (prettier))
                  ("JSON"  (prettier))
                  ("CSS"  (prettier))
                  ("HTML" (prettier))
                  ("Lua"   (stylua))
                  ("Rust"  (rustfmt)))))

;; ─────────────────────────────────────────────────────────
;; Tree-sitter
;; ─────────────────────────────────────────────────────────
;; Emacs 31: treesit built-in. Los paquetes legacy tree-sitter /
;; tree-sitter-langs (ubolonton) CONFLICTAN con los modos -ts-mode
;; (error "No language registered for major mode" y font-lock muerto).
;; Eliminados; gramáticas vía treesit-language-source-alist abajo.


;; Fuentes de gramáticas para el treesit built-in (M-x treesit-install-language-grammar)
(use-package treesit
  :straight nil :ensure nil
  :config
  (setq treesit-language-source-alist
        '((typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                      "master" "typescript/src")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript"
               "master" "tsx/src")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
          (css "https://github.com/tree-sitter/tree-sitter-css")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (lua "https://github.com/tree-sitter-grammars/tree-sitter-lua")
          (jsdoc "https://github.com/tree-sitter/tree-sitter-jsdoc"))))

(defun my/setup-evil-ts-textobjs ()
  "Bind tree-sitter text objects. Body lives in a defun so the
`evil-textobj-tree-sitter-get-textobj' macro is NOT expanded while
init.el loads (its expander requires tree-sitter, defeating lazy load)."
  (define-key evil-outer-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f"
    (evil-textobj-tree-sitter-get-textobj "function.inner"))
  (define-key evil-outer-text-objects-map "a"
    (evil-textobj-tree-sitter-get-textobj ("conditional.outer" "loop.outer")))
  (define-key evil-outer-text-objects-map "m"
    (evil-textobj-tree-sitter-get-textobj "import"
      '((python-mode      . ((import_statement) @import))
        (python-ts-mode   . ((import_statement) @import))
        (rust-mode        . ((use_declaration) @import))
        (typescript-ts-mode . ((import_statement) @import))
        (tsx-ts-mode        . ((import_statement) @import))
        (js-ts-mode         . ((import_statement) @import))))))

(use-package evil-textobj-tree-sitter
  :after (evil tree-sitter)
  :config (my/setup-evil-ts-textobjs))

;; ─────────────────────────────────────────────────────────
;; Treemacs (file tree sidebar)
;; ─────────────────────────────────────────────────────────
(use-package treemacs
  :commands (treemacs)   ; defer: loads on SPC t t
  :custom
  (treemacs-width 30)
  (treemacs-indentation 2)
  (treemacs-show-hidden-files t)
  :config
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode t))

(use-package treemacs-evil
  :after (treemacs evil))

;; ─────────────────────────────────────────────────────────
;; Projectile-style project management via project.el
;; ─────────────────────────────────────────────────────────
(use-package project
  :ensure nil
  :config
  ;; Teach project.el about common project markers
  (setq project-vc-extra-root-markers '(".project" "Cargo.toml" "Makefile" "meson.build" "CMakeLists.txt")))

;; ─────────────────────────────────────────────────────────
;; Ediff (better diff)
;; ─────────────────────────────────────────────────────────
(use-package ediff
  :ensure nil
  :config
  (setq ediff-window-setup-function 'ediff-setup-windows-plain
        ediff-split-window-function 'split-window-horizontally))

;; ─────────────────────────────────────────────────────────
;; Rainbow Delimiters (visual paren matching)
;; ─────────────────────────────────────────────────────────
(use-package rainbow-delimiters
  :diminish rainbow-delimiters-mode
  :hook (prog-mode . rainbow-delimiters-mode))

;; ─────────────────────────────────────────────────────────
;; Expand-region (semantic selection)
;; ─────────────────────────────────────────────────────────
(use-package expand-region
  :general
  (general-define-key
   :states '(normal visual)
   "C-=" 'er/expand-region
   "C--" 'er/contract-region))

;; ─────────────────────────────────────────────────────────
;; ws-butler: trim whitespace on save (only changed lines)
;; ─────────────────────────────────────────────────────────
(use-package ws-butler
  :diminish ws-butler-mode
  :hook (prog-mode . ws-butler-mode))

;; ─────────────────────────────────────────────────────────
;; Smart compile commands per language
;; ─────────────────────────────────────────────────────────
(use-package compile
  :ensure nil
  :config
  (add-hook 'c-mode-common-hook
            (lambda () (setq-local compile-command
                              (concat "gcc -Wall -Wextra -g -o "
                                      (file-name-sans-extension (buffer-name))
                                      " " (buffer-name)))))
  (add-hook 'rust-mode-hook
            (lambda () (setq-local compile-command "cargo build"))))

;; ─────────────────────────────────────────────────────────
;; vterm (proper terminal)
;; ─────────────────────────────────────────────────────────
(use-package vterm
  :commands (vterm)      ; defer: module compilation is expensive
  :custom
  (vterm-max-scrollback 10000)
  (vterm-kill-buffer-on-exit t))

(defun my/vterm-files-to-occur-clean ()
  (interactive)
  (let ((seen (make-hash-table :test 'equal))
        (results '())
        (regex "\\(~?/[^ \n:()]+\\|\\.?\\.?/[^ \n:()]+\\)\\(:[0-9]+\\)?"))

    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward regex nil t)
        (let* ((raw (match-string 0))
               (parts (split-string raw ":"))
               (file (expand-file-name (car parts)))
               (line (cadr parts)))

          (when (and (file-exists-p file)
                     (not (gethash raw seen)))
            (puthash raw t seen)
            (push (if line
                      (format "%s:%s" file line)
                    file)
                  results)))))

    (let ((buf (get-buffer-create "*vterm-files*")))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (dolist (r (nreverse results))
            (insert r "\n")))
        (goto-char (point-min))
        (read-only-mode 0)
        (local-set-key (kbd "RET") #'find-file-at-point))

      (pop-to-buffer buf))))

;; ─────────────────────────────────────────────────────────
;; Diminish: applied via :diminish in each package (works with
;; lazy loading — the old eager block silently failed on deferred modes)
;; ─────────────────────────────────────────────────────────
(use-package diminish
  :defer t)

;; ─────────────────────────────────────────────────────────
;; Emacs defaults (completion engine config)
;; ─────────────────────────────────────────────────────────
(use-package emacs
  :ensure nil
  :custom
  (tab-always-indent 'complete)
  (text-mode-ispell-word-completion nil)
  (read-extended-command-predicate #'command-completion-default-include-p))

;; ─────────────────────────────────────────────────────────
;; GCMH: garbage collector tuning (smoother experience)
;; ─────────────────────────────────────────────────────────
(use-package gcmh
  :config (gcmh-mode 1))

;; ─────────────────────────────────────────────────────────
;; Recentf (track recent files)
;; ─────────────────────────────────────────────────────────
(use-package recentf
  :straight nil
  :config
  (recentf-mode 1)
  (setq recentf-max-saved-items 100))

;; ─────────────────────────────────────────────────────────
;; System clipboard as UTF-8 (fix: emoji copied with emacs
;; pasted as "?" — default compound-text can't encode them)
;; ─────────────────────────────────────────────────────────
(set-selection-coding-system 'utf-8)
(setq select-enable-clipboard t)

;; ─────────────────────────────────────────────────────────
;; Font
;; ─────────────────────────────────────────────────────────
(set-face-attribute 'default nil
                    :family "MesloLGL Nerd Font" :height 133)
    (set-face-attribute 'fixed-pitch nil :family "MesloLGL Nerd Font")

(use-package ligature
  :straight (:host github :repo "mickeynp/ligature.el")
  :commands (ligature-mode)
  :hook ((prog-mode markdown-mode) . ligature-mode)
  :config
  (ligature-set-ligatures
   '(prog-mode markdown-mode)
   '("==" "===" "!=" "!==" "=>" "->" "<-" ">=" "<=" "&&" "||"
     "::" ".." "..." ">>" "<<" "**" "//" "/*" "*/" "++" "--")))

;; ─────────────────────────────────────────────────────────
;; Font size: transient menu (SPC F t) — +/-/0 = subir/bajar/reset
;; ─────────────────────────────────────────────────────────
(defconst my/default-font-height 133)         ; 13.3pt

(defun my/font-height-bump (delta)
  "Change default font height by DELTA (10 = 1pt)."
  (let ((new (+ delta (face-attribute 'default :height))))
    (set-face-attribute 'default nil :height new)
    (message "Font: %.1fpt" (/ new 10.0))))

(defun my/font-size-increase () (interactive) (my/font-height-bump 10))
(defun my/font-size-decrease () (interactive) (my/font-height-bump -10))
(defun my/font-size-reset ()
  (interactive)
  (set-face-attribute 'default nil :height my/default-font-height)
  (message "Font reset: %.1fpt" (/ my/default-font-height 10.0)))

(use-package transient
  :config
  (transient-define-prefix my/font-size-menu ()
    "Font size"
    [["Adjust"
      ("+" "increase 1pt" my/font-size-increase)
      ("-" "decrease 1pt" my/font-size-decrease)
      ("0" "reset" my/font-size-reset)]]))

;; ── Mail: notmuch + smtpmail + pass (Gmail kcurtet@gmail.com) ──
(use-package notmuch
  :straight nil
  :ensure nil
  :load-path "/usr/share/emacs/site-lisp"
  :commands (notmuch notmuch-mua-new-mail)
  :config
  (setq notmuch-search-oldest-first nil
        notmuch-draft-folder "[Gmail]/Borradores"
        notmuch-draft-tags '(+draft)
        ;; Gmail auto-saves SMTP-sent mail; FCC would duplicate after mbsync push
        notmuch-fcc-dirs nil)
  ;; evil grabs n/N/p in show buffers; make n/p walk messages instead
  (evil-define-key '(normal motion) notmuch-show-mode-map
    "n" #'my/notmuch-show-next-or-next-thread
    "p" #'my/notmuch-show-prev-or-prev-thread
    "e" #'notmuch-show-save-attachments)
  ;; evil-collection-notmuch sets a buffer-local aux map with C-j/C-k bound
  ;; when a real show buffer opens; that beats evil-define-key on the mode map.
  ;; Re-bind locally after its setup hook runs.
  (defun my/notmuch-show-override-keys ()
    (evil-local-set-key 'normal (kbd "C-j") #'my/notmuch-show-next-or-next-thread)
    (evil-local-set-key 'normal (kbd "C-k") #'my/notmuch-show-prev-or-prev-thread)
    ;; C-d scrolls half-page down but C-u is universal-argument; make it the
    ;; symmetric half-page up (numeric prefix is useless while reading mail)
    (evil-local-set-key 'normal (kbd "C-u") #'evil-scroll-up))
  (add-hook 'notmuch-show-mode-hook #'my/notmuch-show-override-keys 90)
  ;; evil-collection `d' only toggles `deleted'; stock notmuch also strips
  ;; inbox/unread so deleted mail leaves inbox searches (emacs search does
  ;; not apply notmuch's exclude_tags). Mirror stock semantics on delete.
  (defun my/notmuch-delete-strips-inbox (orig tag mode &optional next-function)
    ;; Strip BEFORE calling ORIG: ORIG's next-function moves point off the
    ;; thread line, so tagging after it would hit "Nothing to tag!".
    (let ((deleting (and (string= tag "deleted")
                         (not (member tag
                                      (funcall (intern
                                                (format "notmuch-%s-get-tags" mode)))))))
          (set (intern (format "notmuch-%s-tag" mode))))
      (when deleting
        (funcall set (list "-inbox" "-unread")))
      (funcall orig tag mode next-function)))
  (advice-add 'evil-collection-notmuch-toggle-tag :around
              #'my/notmuch-delete-strips-inbox))

(defun my/notmuch-show-next-or-next-thread ()
  "Next message in thread; at the last one, jump to next thread in list."
  (interactive)
  (let ((before (notmuch-show-get-message-id)))
    (notmuch-show-next-message)
    (when (equal before (notmuch-show-get-message-id))
      (condition-case nil
          (notmuch-show-next-thread-show)
        (error (message "No more threads"))))))

(defun my/notmuch-show-prev-or-prev-thread ()
  "Previous message in thread; at the first one, jump to previous thread."
  (interactive)
  (let ((before (notmuch-show-get-message-id)))
    (notmuch-show-previous-message)
    (when (equal before (notmuch-show-get-message-id))
      (condition-case nil
          (notmuch-show-previous-thread-show)
        (error (message "No previous thread"))))))

(use-package message
  :straight nil
  :ensure nil
  :config
  (setq message-send-mail-function 'smtpmail-send-it
        message-kill-buffer-on-exit t))

(use-package smtpmail
  :straight nil
  :ensure nil
  :config
  (setq smtpmail-smtp-server "smtp.gmail.com"
        smtpmail-smtp-service 587
        smtpmail-stream-type 'starttls
        user-mail-address "kcurtet@gmail.com"))

;; Secrets live in pass; entry smtp.gmail.com has host/user/port metadata
(auth-source-pass-enable)

(defun my/mail-sync ()
  "Fetch mail with mbsync and index with notmuch."
  (interactive)
  (message "Syncing mail…")
  (async-shell-command "mail-sync" "*mail-sync*"))

(leader
  "m"  '(:ignore t :wk "mail")
  "mm" '(notmuch :wk "notmuch")
  "mc" '(notmuch-mua-new-mail :wk "compose")
  "ms" '(my/mail-sync :wk "sync"))

;; ─────────────────────────────────────────────────────────
;; Notes: Denote (sample config del manual, keybinds en SPC n)
;; ─────────────────────────────────────────────────────────
(use-package denote
  :demand t
  :hook
  (;; En .txt los enlaces de Denote no son clicables por defecto;
   ;; este minor mode los fontifica (org/markdown ya lo hacen)
   (text-mode . denote-fontify-links-mode)
   ;; Colores para los nombres Denote en Dired (todos los directorios)
   (dired-mode . denote-dired-mode))
  :bind
  ;; Binds específicos de Dired
  (:map dired-mode-map
        ("C-c C-d C-i" . denote-dired-link-marked-notes)
        ("C-c C-d C-r" . denote-dired-rename-files)
        ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
        ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))
  :config
  ;; Directorio de notas
  (setq denote-directory (expand-file-name "~/Documentos/k0rt3x/"))
  ;; Formato por defecto: Markdown con YAML front matter
  (setq denote-file-type 'markdown-yaml)
  ;; t (cambia del sample del manual): el agente crea notas headless vía
  ;; emacsclient; con nil el buffer queda sin guardar y el archivo nunca existe
  (setq denote-save-buffers t)
  ;; Keywords: base del manual + tags de tipo de nota (canon en AGENTS.md del vault)
  (setq denote-known-keywords '("emacs" "philosophy" "politics" "economics"
                                 "reference" "permanent" "inbox" "session" "moc" "archive"))
  ;; Plantillas por tipo de nota (X6 de la spec del vault), sintaxis md
  (setq denote-templates
        '((reference . "## Status: to-read\n## Fuente: \n## Notas: \n")
          (permanent . "## Tesis: \n## Contexto: \n## Preguntas abiertas: \n")
          (session . "## Modo: \n## Preguntas: \n## Conclusiones: \n")))
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-prompts '(title keywords))
  (setq denote-excluded-directories-regexp nil)
  (setq denote-keywords-to-not-infer-regexp nil)
  (setq denote-rename-confirmations '(rewrite-front-matter modify-file-name))

  ;; Elegir fechas con la interfaz avanzada de Org
  (setq denote-date-prompt-use-org-read-date t)

  ;; Renombrar buffers de Denote automáticamente (ver
  ;; `denote-rename-buffer-format')
  (denote-rename-buffer-mode 1)

  ;; ── Keybinds globales en el leader: SPC n ──
  (leader
    "n"   '(:ignore t :wk "notes")
    "nn"  '(denote :wk "new note")
    "nd"  '(denote-dired :wk "denote dired")
    "ng"  '(denote-grep :wk "grep notes")
    "nl"  '(denote-link :wk "link")
    "nL"  '(denote-add-links :wk "add links")
    "nb"  '(denote-backlinks :wk "backlinks")
    "nq"  '(:ignore t :wk "query links")
    "nqc" '(denote-query-contents-link :wk "contents link (grep)")
    "nqf" '(denote-query-filenames-link :wk "filenames link (dired)")
    "nr"  '(denote-rename-file :wk "rename file")
    "nR"  '(denote-rename-file-using-front-matter :wk "rename (front matter)")))

(provide 'init)
;;; init.el ends here

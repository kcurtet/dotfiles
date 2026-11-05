;;; -*- lexical-binding: t; -*-
(setq package-enable-at-startup nil)

;; ── Startup speed ──
;; Disable UI elements here: the frame is not yet drawn, so no resize
;; flicker and no wasted work that init.el would have to undo.
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(setq frame-inhibit-implied-resize t
      inhibit-splash-screen t
      inhibit-startup-screen t
      inhibit-startup-buffer-menu t
      inhibit-startup-echo-area-message t)

;; Native-comp: don't spam *Warnings* buffers on async compiles
(setq native-comp-async-report-warnings-errors nil)

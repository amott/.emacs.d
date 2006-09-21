;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Programming support
;;;
;;; Sets up general programming options and loading of language modes

;;; Non-specific setup

;; Blink those parens
(if (require 'paren nil t)
    (show-paren-mode t))

;; Adapt those fills
(if (require 'filladapt nil t)
    (progn
      ;; Disable built-in adaptive filling
      (setq adaptive-fill-mode nil)
      ;; This is a little weird.  filladapt overloads a bunch of
      ;; autofill's functions, so just by loading it and setting the
      ;; mode variable it will come to life.  The modeline won't be
      ;; updated unless turn-on-filladapt-mode is called from every
      ;; buffer.
      (setq filladapt-mode-line-string " F*")))

;; Tabs are evil.  Use spaces to indent
(setq-default indent-tabs-mode nil)

;; Autoindent after a line
(global-set-key "\C-m" 'newline-and-indent)

;; Self-explanatory
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)

;;; Set up individual language modes

(require 'atc-features)

;; C/C++ is too scary to fit here
(load "atc-cc")

;; Python
(atc:autoload-mode 'python-mode "python-mode" "\\.py$" "python")
(atc:add-mode-features 'python-mode-hook '(filladapt flyspell-prog))

;; MIT Scheme
;(atc:autoload-mode 'scheme-mode "xscheme" "\\.scm$")

;; PLT Scheme
(defun scheme-send-buffer ()
  (interactive)
  (scheme-send-region (point-min)
                      (point-max)))
(defmodefeature quack-send-buffer
  (local-set-key "\C-c\C-c" 'scheme-send-buffer)
  ;; Quack inadvertently changes the semantics of scheme-proc in bad
  ;; ways.  It advises it so that, if no current inferior Scheme
  ;; buffer exists, it starts a new one.  However, it has the
  ;; side-effect of switching to this new buffer.  This break
  ;; functions like scheme-send-region, which then try to read from
  ;; the Scheme process buffer instead of the buffer in which they
  ;; were called.
  (defadvice scheme-proc (around atc-ad-fix-quack first nil activate)
    (save-current-buffer
      ad-do-it)))

(atc:autoload-mode 'scheme-mode "quack" "\\.scm$")
(atc:add-mode-features 'scheme-mode-hook '(autofill filladapt
                                                    flyspell-prog
                                                    quack-send-buffer))
(setq quack-fontify-style 'emacs
      ;; Alas, this only works with plt-style fontification
      quack-pretty-lambda-p t
      quack-run-scheme-always-prompts-p nil)

;; Lisp
(atc:add-mode-features '(lisp-mode-hook emacs-lisp-mode-hook)
                       '(autofill filladapt flyspell-prog))

;; Shell
(atc:add-mode-features 'sh-mode-hook
                       '(;autofill
                         filladapt flyspell-prog shell-newline))

;; HTML, text, and Subversion log messages
(atc:add-mode-features '(html-mode-hook text-mode-hook)
                       '(autofill flyspell-full))
(atc:add-mode-features 'text-mode-hook
                       '(plain-newline filladapt))
(atc:autoload-mode 'svn-commit-mode "svn-commit-mode"
                   "svn-commit\\(\\.[0-9]+\\)?\\.tmp")

;; Latex (AUCTeX)
(defmodefeature latex-bindings
  (local-set-key "\M-q" 'LaTeX-fill-paragraph)
  ;; This gets unset by latex-mode
  (local-set-key "\C-m" 'newline-and-indent))
(defmodefeature latex-faces
  ;; Make all of the section faces small
  (dolist (face '(font-latex-title-1-face
                  font-latex-title-2-face
                  font-latex-title-3-face))
    (face-spec-set face '((t (:inherit font-latex-title-4-face)))))
  ;; Add a "problem" title keyword
  (setq font-latex-match-title-1-keywords '("problem"))
  (font-latex-match-title-1-make))

(atc:autoload-mode 'latex-mode "tex-site" "\\.tex$")
(atc:add-mode-features 'LaTeX-mode-hook
                       '(autofill filladapt flyspell-full
                                  latex-bindings latex-faces))

;;; Fix flyspell

;; Flyspell has major issues when replaying keyboard macros.  I don't
;; know if this fix will correctly check all changes made by keyboard
;; macros (I think it will), but it's well worth it
(defadvice flyspell-post-command-hook (around flyspell-in-macros-bug
                                       activate)
  (unless executing-kbd-macro
    ad-do-it))

;; flyspell only knows about tex-mode by default
;; Not necessary with new version of flyspell
;(put 'latex-mode 'flyspell-mode-predicate 'tex-mode-flyspell-verify)

;; Assembly
(atc:autoload-mode '8051-mode "8051-mode" "\\.asm$")
(atc:add-mode-features '8051-mode-hook '(autofill filladapt
                                                  flyspell-prog))

;; RSCC Grammar
(atc:autoload-mode 'rsccg-mode "rsccg-mode" "\\.g$")

;; Haskell
(atc:autoload-mode 'haskell-mode "haskell-mode" "\\.hs$")
(atc:add-mode-features 'haskell-mode '(flyspell-prog))

;; Literate Haskell
(atc:autoload-mode 'latex-mode "tex-site" "\\.lhs$")
(require 'mmm-auto)
(mmm-add-classes
 '((literate-haskell
    :submode haskell-mode
    :front "\\\\begin[ \t]*{code}\n"
    ;; The \n at the beginning of back prevents the mis-fontification
    ;; of the line matching this regex.  Without this, haskell-mode
    ;; will fontify it when the haskell-mode region is edited
    :back "\n\\\\end[ \t]*{code}")))
(add-to-list 'mmm-mode-ext-classes-alist
             '(latex-mode "\\.lhs$" literate-haskell))

;; XML
(when (load "nxml-mode/rng-auto" t)
  (add-to-list 'auto-mode-alist
               '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\)\\'" . nxml-mode))
  ;; Based on http://www.emacswiki.org/cgi-bin/wiki/NxmlMode
  (if (boundp 'magic-mode-alist)
      ;; Emacs 22?
      (add-to-list magic-mode-alist '("<\\?xml " . nxml-mode))
    (add-hook 'hack-local-variables-hook
              (lambda ()
                (save-excursion
                  (goto-char (point-min))
                  (when (looking-at "^<\\?xml ")
                    (nxml-mode)))))))

;; Programming support for the Go language

(defun atc:go-mode-setup ()
  ;; go-mode integrates godoc and godef support if they're installed
  (atc:want-executable "godoc" "Run go get code.google.com/p/go.tools/cmd/godoc")
  (atc:want-executable "godef" "Run go get code.google.com/p/rog-go/exp/cmd/godef")
  (when (atc:want-fbound 'go-eldoc-setup 'go-eldoc)
    (go-eldoc-setup))
  (when (and (atc:want-fbound 'company-go 'company-go)
             (atc:want-executable "gocode" "Run go get -u github.com/nsf/gocode"))
    (set (make-local-variable 'company-backends) '(company-go))
    (company-mode)))

(eval-after-load 'go-mode
  (progn
    (add-hook 'go-mode-hook #'atc:go-mode-setup)
    (when (atc:want-executable "gofmt" "Add Go to your PATH")
      (add-hook 'before-save-hook #'gofmt-before-save))
    (when (atc:want-executable "goimports" "Run go get code.google.com/p/go.tools/cmd/goimports")
      (setq gofmt-command "goimports"))))

;; Style for C/assembly code in Go trees
;; XXX Extend c-choose-style?  Still need this for assembly
(add-hook 'find-file-hook
          (lambda ()
            (when (string-match
                   (concat "^" (regexp-quote (expand-file-name "~/go")))
                   (buffer-file-name))
              (setq indent-tabs-mode t
                    c-basic-offset 8))))

;; Company mode (for Go completion)
;; XXX Requires company, company-go
(setq company-tooltip-limit 20)
(setq company-idle-delay .3)
(setq company-echo-delay 0)
(setq company-go-insert-arguments nil)

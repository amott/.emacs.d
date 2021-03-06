;; Helpers for depending on things

(defvar atc:want--packages nil)
(defvar atc:want--messages nil)

(defvar atc:want--timer nil)

(defun atc:want--ensure-report ()
  (unless atc:want--timer
    (setq atc:want--timer (run-with-idle-timer 0.5 nil #'atc:want--report))))

(defun atc:want-fbound (sym pkg)
  (if (fboundp sym)
      t
    (add-to-list 'atc:want--packages pkg t)
    (atc:want--ensure-report)
    nil))

(defun atc:want-executable (command install)
  (if (executable-find command)
      t
    (add-to-list 'atc:want--messages
                 (format "Missing %s. %s" command install) t)
    (atc:want--ensure-report)
    nil))

(defun atc:want--report ()
  (let ((messages
         (append
          (when atc:want--packages
            (list
             (format "Missing packages %s. Use M-x package-install"
                     atc:want--packages)))
          atc:want--messages)))
    (message "%s" (mapconcat 'identity messages "\n")))
  (setq atc:want--packages nil
        atc:want--messages nil
        atc:want--timer nil))

(load-file "~/.emacs.d/whitespace-mode.el")

(setq c-basic-offset 4)
(setq tab-width 4)
(setq indent-tabs-mode nil)

(global-font-lock-mode 1)

(defun python-mode-untabify ()
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "[ \t]+$" nil t)
      (delete-region (match-beginning 0) (match-end 0)))
    (goto-char (point-min))
    (if (search-forward "\t" nil t)
	(untabify (1- (point)) (point-max))))
  nil)

(add-hook 'python-mode-hook
	  '(lambda ()
	     (make-local-variable 'write-contents-hooks)
	     (add-hook 'write-contents-hooks 'python-mode-untabify)))

;; nuke trailing whitespaces when writing to a file
(add-hook 'write-file-hooks 'delete-trailing-whitespace)

;; display only tails of lines longer than 80 columns, tabs and
;; trailing whitespaces
(setq whitespace-line-column 72
      whitespace-style '(tabs trailing lines-tail empty indentation::space space-after-tab::space space-before-tab::space))

;; activate minor whitespace mode when in python mode
(add-hook 'python-mode-hook 'whitespace-mode)

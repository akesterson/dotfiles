
(setq w3m-use-cookies t)
(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
;; optional keyboard short-cut
(global-set-key "\C-xm" 'browse-url-at-point)

(setq w3m-command-arguments '("-pauth" "USER:PASSWORD"))

(setq w3m-async-exec t)

(setq w3m-use-title-buffer-name t)

(defun w3m-new-buffer nil
  "Opens a new, empty w3m buffer."
  "As opposed to `w3m-copy-buffer', which opens a non-empty buffer.
 This ought to be snappier, as the old buffer needs not to be rendered.
 To be quite honest, this new function doesn't open a buffer completely
 empty, but visits the about: pseudo-URI that is going to have to
 suffice for now."
  (interactive)
  (w3m-goto-url-new-session "about://"))

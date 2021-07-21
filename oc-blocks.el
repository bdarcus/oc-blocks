;;; oc-blocks.el --- Component processors for org-cite. -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; (setq org-cite-insert-processor 'oc-blocks-insert)
;;
;;; Code:

(require 'oc)
(require 'oc-blocks-insert)


;; load last
(org-cite-register-processor 'oc-blocks
  :insert oc-blocks-insert)

(provide 'org-cite-blocks)
(provide 'oc-blocks)
;;; oc-blocks.el ends here

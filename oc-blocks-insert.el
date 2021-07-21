;;; oc-blocks-insert.el --- Enhanced org-cite insert processor. -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Bruce D'Arcus
;;
;; Author: Bruce D'Arcus <https://github.com/bdarcus>
;; Maintainer: Bruce D'Arcus <bdarcus@gmail.com>
;; Created: July 21, 2021
;; Modified: July 21, 2021
;; Version: 0.0.1
;; Keywords: ("convenience")
;; Homepage: https://github.com/bdarcus/oc-blocks
;; Package-Requires: ((emac "27.1")(org "9.5"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 'oc)

;; Since we want to generate preview data from the export processors, load them.
(require 'oc-natbib)
(require 'oc-biblatex)
(require 'oc-csl)
(require 'citeproc)

(defface oc-blocks-insert-style-preview
  ;; Not sure if this is the best parent face.
    '((t :inherit minibuffer-prompt))
  "Face for org-cite previews."
  :group 'oc-blocks-insert)

(defcustom oc-blocks-completion-function 'bibtex-actions-read
  "A completion function that returns a list of citation keys."
  :type '(choice
          (function-item :tag "ivy-bibtex (ivy)" :value ivy-bibtex-read) ; not sure if this is right, but demos the idea
          (function-item :tag "helm-bibtex (helm)" :value helm-bibtex-read)
          (function-item :tag "bibtex-actions (completing-read)" :value bibtex-actions-read)
          (function :tag "Custom function"))
  :group 'oc-blocks-insert)

;;; Internal variables

(defvar oc-blocks-insert--csl-processor-cache nil
  "Cache for the citation preview processor.")

(make-variable-buffer-local 'oc-blocks-insert--csl-processor-cache)

(defun oc-blocks-insert--csl-processor ()
  "Return a `citeproc-el' processor for style preview."
  (or oc-blocks-insert--csl-processor-cache
      (let* ((bibliography (org-cite-list-bibliography-files))
             (processor
              (citeproc-create
               org-cite-csl--fallback-style-file
               (org-cite-csl--itemgetter bibliography)
               (org-cite-csl--locale-getter))))
        (setq oc-blocks-insert--csl-processor-cache processor)
        processor)))

(defun oc-blocks-insert-select-style ()
"Complete a citation style for org-cite with preview."
  (interactive)
  (let* ((oc-styles (oc-blocks-insert--styles-candidates))
         (style
          (completing-read
           "Styles: "
           (lambda (str pred action)
             (if (eq action 'metadata)
                 `(metadata
                   (annotation-function . oc-blocks-insert--style-preview-annote)
                   (cycle-sort-function . identity)
                   (display-sort-function . identity)
                   (group-function . oc-blocks-insert--styles-group-fn))
               (complete-with-action action oc-styles str pred))))))
    (string-trim style)))

(defun oc-blocks-insert--styles-candidates ()
  "Generate candidate list."
  ;; TODO extract the style+variant strings from 'org-cite-supported-styles'.
  (cl-loop for style in
           '(("test" . "test preview"))
           collect (cons
                    (concat "  " (truncate-string-to-width (car style) 20 nil 32)) (cdr style))))

(defun oc-blocks-insert--styles-group-fn (style transform)
  "Return group title of STYLE or TRANSFORM the candidate.
This is a group-function that groups org-cite style/variant
strings by style."
    (let* ((style-str (string-trim style))
           (short-style
            (if (string-match "^/[bcf]*" style-str) "default"
              (car (split-string style-str "/")))))
    (if transform
        ;; Use the candidate string as is, but add back whitespace alignment.
        (concat "  " (truncate-string-to-width style-str 20 nil 32))
      ;; Transform for grouping and display.
      (cond
       ((string= short-style "default") "Default")
       ((string= short-style "author") "Author-Only")
       ((string= short-style "locators") "Locators-Only")
       ((string= short-style "text") "Textual/Narrative")
       ((string= short-style "nocite") "No Cite")
       ((string= short-style "noauthor") "Suppress Author")))))

(defun oc-blocks-insert--style-preview-annote (style &optional _citation)
  "Annotate STYLE with CITATION preview."
  ;; TODO rather than use the alist, run the export processors on the citation.
  (let* ((preview (cdr (assoc style (oc-blocks-insert--styles-candidates))))
         ;; TODO look at how define-face does this.
         (formatted-preview (truncate-string-to-width preview 50 nil 32)))
    (propertize formatted-preview 'face 'oc-blocks-insert-style-preview)))

;;; insert keys

(defun oc-blocks-insert-select-keys (&optional multiple)
  "Return a list of keys when MULTIPLE, or else a key string.
This is the interface between the completion function and org-cite."
  (let ((references
         (funcall-interactively oc-blocks-completion-function)))
    (if multiple
        references
      (car references))))

;; Load this last.

(defvar oc-blocks-insert
  (org-cite-make-insert-processor
   #'oc-blocks-insert-select-keys
   #'oc-blocks-insert-select-style))

;; The following are not functionally different ATM, but they demonstrate one
;; way to package different insert processors for different front-ends.

(defvar oc-blocks-insert-ivy
  (org-cite-make-insert-processor
   #'oc-blocks-insert-select-keys
   #'oc-blocks-insert-select-style))

(defvar oc-blocks-insert-helm
  (org-cite-make-insert-processor
   #'oc-blocks-insert-select-keys
   #'oc-blocks-insert-select-style))

(provide 'org-cite-blocks-insert)
(provide 'oc-blocks-insert)
;;; oc-blocks-insert.el ends here

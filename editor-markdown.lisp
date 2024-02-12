;;; Copyright (c) 2024, April Simone
;;; SPDX-License-Identifier: BSD-2-Clause-Patent

;;; Usage: Load this file.

(defpackage editor-markdown
  (:add-use-defaults))
(in-package "EDITOR-MARKDOWN")

(ql:quickload :cl-ppcre)


;;; Easy Custom Settings

(defparameter *sans-serif-font-family-name*
  "Sarasa UI SC")

(defparameter *monospace-font-family-name*
  "Sarasa Mono SC")

;;; END

;;; Fonts

(editor:make-face 'md-default-face
                  :font (gp:find-best-font (capi:create-dummy-graphics-port)
                                           (gp:make-font-description :family *sans-serif-font-family-name* :size 10))
                  :if-exists :overwrite)

(defparameter *bold-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *sans-serif-font-family-name* :size 10
                                               :weight :bold)))

(defparameter *italic-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *sans-serif-font-family-name* :size 10
                                               :slant :italic)))

(defparameter *bold-italic-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *sans-serif-font-family-name* :size 10
                                               :weight :bold :slant :italic)))

(defparameter *strikeout-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *sans-serif-font-family-name* :size 10
                                               :slant :italic)))

(defparameter *header-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *sans-serif-font-family-name* :size 12
                                               :weight :bold)))

(defparameter *mono-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *monospace-font-family-name* :size 10)))

(defparameter *mono-bold-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *monospace-font-family-name* :size 10
                                               :weight :bold)))

;;; END

;;; Regex and Face for syntax

(defparameter *code-block-region-regexp*
  (ppcre:create-scanner "((?<=^)|(?<=\\n))(~{3,}|`{3,})(.+\\n)?[\\s\\S]*?(~{3,}|`{3,})[ \\t]*(\\n|$)"))
(editor:make-face 'md-code-block-delimiter-face
                  :font *mono-bold-font*
                  :foreground :forestgreen
                  :background :lightcyan2
                  :if-exists :overwrite)
(editor:make-face 'md-code-block-face
                  :font *mono-font*
                  :background :lightcyan2
                  :if-exists :overwrite)

(defparameter *split-line-regexp*
  (ppcre:create-scanner "((?<=^)|(?<=\\n\\n))([ \\t]*[\\*-]){3,}[ \\t]*(\\n|$)"))
(editor:make-face 'md-split-line-face
                  :background :grey60
                  :foreground :firebrick
                  :if-exists :overwrite)

(defparameter *header-regexp*
  (ppcre:create-scanner "^#{1,6} \\S.*$"
                        :multi-line-mode t))
(editor:make-face 'md-header-face
                  :font *header-font*
                  :foreground :blue
                  :if-exists :overwrite)

(defparameter *unordered-list-regexp*
  (ppcre:create-scanner "^[> \\t]*[\\*\\+-] \\S.*$"
                        :multi-line-mode t))
(defparameter *ordered-list-regexp*
  (ppcre:create-scanner "^[> \\t]*\\d{1,9}[\\.)] \\S.*$"
                        :multi-line-mode t))
(editor:make-face 'md-list-face
                  :font *italic-font*
                  :foreground :darkgoldenrod
                  :if-exists :overwrite)

(defparameter *quote-regexp*
  (ppcre:create-scanner "((?<=^)|(?<=\\n))[ \\t]*(> )+.*(\\n|$)"))
(editor:make-face 'md-quote-face
                    :background :gray90
                    :foreground :red4
                    :if-exists :overwrite)

(defparameter *link-ref-regexp*
  (ppcre:create-scanner "(\\[.+?\\](\\(.*?\\))?)|(<.+?>)"))
(defparameter *link-def-regexp*
  (ppcre:create-scanner "((?<=^)|(?<=\\n))[ \\t]*\\[.+\\]: \\S.*(\\n|$)"))
(editor:make-face 'md-link-face
                  :font *italic-font*
                  :background :lightcyan2
                  :foreground :blue
                  :if-exists :overwrite)

(defparameter *image-regexp*
  (ppcre:create-scanner "!(\\[.*?\\]((\\(.*?\\))|<.*?>)?)"))

(defparameter *bold-regexp*
  (ppcre:create-scanner "((?<=[^\\*])\\*{2}[^\\*\\n]+?\\*{2})|(_{2}[^_\\n]+?_{2})"))
(editor:make-face 'md-bold-face :font *bold-font*
                  :foreground :orchid :if-exists :overwrite)

(defparameter *italic-regexp*
  (ppcre:create-scanner "((?<=[^\\*])\\*[^\\*\\n]+?\\*)|(_[^_\\n]+?_)"))
(editor:make-face 'md-italic-face
                  :font *italic-font*
                  :foreground :orchid
                  :if-exists :overwrite)

(defparameter *bold-italic-regexp*
  (ppcre:create-scanner "((?<=[^\\*])\\*{3}[^\\*\\n]+?\\*{3})|(_{3}[^_\\n]+?_{3})"))
(editor:make-face 'md-bold-italic-face
                  :font *bold-italic-font*
                  :foreground :orchid
                  :if-exists :overwrite)

(defparameter *strikeout-regexp*
  (ppcre:create-scanner "\\~{2}[^~\\n]+?\\~{2}"))
(editor:make-face 'md-strikeout-face
                  :font *strikeout-font*
                  :background :lightpink
                  :if-exists :overwrite)

(defparameter *code-regexp*
  (ppcre:create-scanner "((?<=[^`])`{2}.+?`{2})|(`.+?`)"))
(editor:make-face 'md-code-face
                  :font *mono-font*
                  :background :honeydew
                  :if-exists :overwrite)

;;; END

;;; Syntax Highlight Function

(defun fontify-syntactically-region (start end)
  (editor:with-point ((s start)
                      (e end))
    (let ((str (editor:points-to-string start end))
          (offset (editor:point-offset start))
          (text-regions (list 0)))
      (push-end (length str) text-regions)
      (editor::merge-face-property s e 'md-default-face :modification nil)
      (loop for regexp in (list *link-def-regexp* *quote-regexp* *link-ref-regexp* *image-regexp*
                                *ordered-list-regexp* *unordered-list-regexp* *header-regexp*
                                *italic-regexp* *bold-regexp* *bold-italic-regexp* *strikeout-regexp* *code-regexp*
                                *split-line-regexp*)
            for face in '(
                          md-link-face md-quote-face md-link-face md-link-face
                          md-list-face md-list-face md-header-face
                          md-italic-face md-bold-face md-bold-italic-face md-strikeout-face md-code-face
                          md-split-line-face)
            for matches = (ppcre:all-matches regexp str)
            do (loop for (ms me) on matches by #'cddr
                     do (setf (editor:point-position s) (+ ms offset)
                              (editor:point-position e) (+ me offset))
                        (editor::merge-face-property s e face :modification nil)))
      (editor:buffer-start s)
      (editor:buffer-end e)
      (let ((buffer-str (editor:points-to-string s e))
            (start-offset (editor:point-offset start))
            (end-offset (editor:point-offset end)))
        (ppcre:do-scans (ms me rs re *code-block-region-regexp* buffer-str)
          (when (or (and (> start-offset ms) (< start-offset me))
                    (and (> end-offset ms) (< end-offset me))
                    (and (< start-offset ms) (> end-offset me)))
            (let* ((code-s (or (svref re 2) (svref re 1)))
                   (code-e (svref rs 3)))
              (setf (editor:point-position s) code-s
                    (editor:point-position e) code-e)
              (editor::remove-text-properties s e '(editor:face nil) :modification nil)
              (editor::lisp-font-lock-fontify-syntactically-region s e)
              (editor::lisp-font-lock-fontify-keywords-region s e)
              (editor::alter-text-property s e 'editor:face
                                           #'(lambda (face) (list face 'md-code-block-face))
                                           :modification nil))
            (setf (editor:point-position s) (svref rs 1)
                  (editor:point-position e) (or (svref re 2) (svref re 1)))
            (editor:put-text-property s e 'editor:face 'md-code-block-delimiter-face :modification nil)
            (setf (editor:point-position s) (svref rs 3)
                  (editor:point-position e) me)
            (editor:put-text-property s e 'editor:face 'md-code-block-delimiter-face :modification nil))
          )))))

;;; END

;;; Mode definition

(editor::defmode "Markdown"
  :major-p t
  :vars '((editor::font-lock-fontify-syntactically-region-function
           . fontify-syntactically-region))
  :setup-function #'(lambda (buffer)
                      (setf (editor::buffer-font-lock-mode-p buffer) t)
                      (editor::font-lock-fontify-buffer buffer))
  :cleanup-function #'(lambda (buffer)
                      (setf (editor::buffer-font-lock-mode-p buffer) nil)))

(editor:defcommand "Markdown Mode" (p)
     "Enable Markdown Mode."
     "Enable Markdown Mode."
  (declare (ignore p))
  (setf (editor:buffer-major-mode (editor:current-buffer)) "Markdown"))

(editor:define-file-type-hook
    ("md" "markdown")
    (buffer type)
  (declare (ignore type))
  (setf (editor:buffer-major-mode buffer) "Markdown"))

;;; END
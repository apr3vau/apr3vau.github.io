;;; Copyright (c) 2024, April Simone
;;; SPDX-License-Identifier: BSD-2-Clause-Patent

;;; Usage: Set the Configures and load this file.

(defpackage colourful
  (:add-use-defaults)
  (:export fontify-keywords-region))
(in-package "COLOURFUL")


;;; Configurations

(defparameter *monospace-font-family-name* "Sarasa Mono SC")

(defparameter *default-font-size* 10)

(defparameter *mono-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *monospace-font-family-name*
                                               :size *default-font-size*)))

(defparameter *mono-italic-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *monospace-font-family-name*
                                               :size *default-font-size*
                                               :slant :italic)))

(defparameter *mono-bold-italic-font*
  (gp:find-best-font (capi:create-dummy-graphics-port)
                     (gp:make-font-description :family *monospace-font-family-name*
                                               :size *default-font-size*
                                               :weight :bold
                                               :slant :italic)))

;;; END

;;; Face definitions / redefinitions

(editor:make-face 'special-keyword-face
                  :bold-p t
                  :foreground :red
                  :if-exists :overwrite)
(editor:make-face 'preprocessor-face
                  :font *mono-italic-font*
                  :foreground :orange
                  :if-exists :overwrite)

(editor:make-face 'editor::font-lock-builtin-face
                  :font *mono-bold-italic-font*
                  :foreground (editor::create-dark-background-switchable-color :orchid :pink)
                  :if-exists :overwrite)
(editor:make-face 'editor::font-lock-type-face
                  :italic-p t
                  :foreground (editor::create-dark-background-switchable-color :forestgreen :yellow)
                  :if-exists :overwrite)
(editor:make-face 'editor::font-lock-function-name-face
                  :bold-p t
                  :foreground (editor::create-dark-background-switchable-color :blue :lightcyan)
                  :if-exists :overwrite)
(editor:make-face 'editor::font-lock-comment-face
                  :font *mono-italic-font*
                  :foreground :firebrick
                  :background :light-red
                  :if-exists :overwrite)
(editor:make-face 'editor::font-lock-keyword-face
                  :font *mono-bold-italic-font*
                  :foreground :purple
                  :if-exists :overwrite)
(editor:make-face 'editor::font-lock-string-face
                  :font *mono-italic-font*
                  :foreground :rosybrown
                  :if-exists :overwrite)

;;; END

;;; Symbol categories

(defvar *definition-symbols*
  (nconc (regexp-find-symbols "^def" :packages (find-package 'common-lisp))
         '(capi:define-interface capi:define-command capi:define-layout capi:define-menu)
         '(editor:defcommand editor:defattribute editor:defmode)
         (regexp-find-symbols "^define" :packages (list (find-package 'editor)
                                                        (find-package 'dspec))
                              :external-only t)
         '(dspec:def)
         '(call-next-method call-method)))

(defvar *builtin-symbols*
  (nconc (mapcar #'intern
                 (mapcar #'string-upcase
                         '("or" "and" "not"
                           "when" "unless" "cond" "if"
                           "case" "ecase" "typecase" "etypecase"
                           "loop" "loop-finish" "do" "do*" "dotimes" "dolist"
                           "do-symbols" "do-external-symbols" "do-all-symbols"
                           "proclaim" "declaim" "declare"
                           "flet" "labels" "macrolet"
                           "block" "return" "return-from"
                           "catch" "throw" "tagbody"
                           "handler-case" "handler-bind"
                           "restart-case" "restart-bind" "with-simple-restart"
                           "let" "let*" "prog" "destructuring-bind"
                           "multiple-value-bind" "multiple-value-prog1" "values"
                           "progn" "progv" "prog1" "prog2"
                           "inline" "unwind-protect"
                           "eval-when"
                           "with-slots" "with-accessors"
                           "with-input-from-string" "with-output-to-string"
                           "with-open-file" "with-open-stream"
                           "with-hash-table-iterator" "with-package-iterator"
                           "with-compilation-unit" "with-standard-io-syntax"
                           "pprint-logical-block" "print-unreadable-object")))
         *definition-symbols*))

;;; END

;;; Fontifying

(defun fontify-single-atom (start end)
  (let* ((str (editor:points-to-string start end))
         (split (split-sequence '(#\:) str))
         (symname (string-upcase (car (last split))))
         (sympak (or (when (> (length split) 1)
                       (find-package (if (string= (car split) "")
                                         "KEYWORD"
                                       (string-upcase (car split)))))
                     (editor::buffer-package-to-use start))))
    (when-let*
        ((sym (find-symbol symname sympak))
         (face (cond ((member sym '(t nil)) nil)
                     ((member sym *builtin-symbols*)
                      'editor::font-lock-keyword-face)
                     ((string= (package-name (symbol-package sym)) "KEYWORD") 
                      'editor::font-lock-builtin-face)
                     ((char= (schar str 0) #\&)
                      'editor::font-lock-type-face)
                     ((or (find-class sym nil) (find-package sym))
                      'editor::font-lock-type-face)
                     ((or (fboundp sym) (macro-function sym))
                      'editor::font-lock-function-name-face)
                     ((boundp sym)
                      'editor::font-lock-variable-name-face)
                     (t nil))))
      (editor::font-lock-apply-highlight start end face))))

(defun fontify-single-form (start end)
  (multiple-value-bind (prefix-len attr)
      (loop for len from 0
            for c = (editor:character-at start len)
            for attr = (editor:character-attribute :lisp-syntax c)
            until (not (eq attr :prefix))
            finally (return (values len attr)))
    (when (> prefix-len 0)
      (editor:with-point ((p-start start))
        (loop repeat prefix-len do (editor::point-after start))
        (editor::font-lock-apply-highlight p-start start 'special-keyword-face)))
    (case attr
      (:open-paren
       (fontify-list start end))
      (:string-quote
       (editor::font-lock-apply-highlight start end editor::*font-lock-string-face*))
      (t
       (fontify-single-atom start end)))))

(defun fontify-declaration-list (lst)
  (let ((1st (pop lst)))
    (editor::font-lock-apply-highlight
     (first 1st) (second 1st)
     'preprocessor-face))
  (dolist (form lst)
    (let ((start (first form))
          (end (second form)))
      (let ((attr (loop for c = (editor:character-at start 0)
                        for attr = (editor:character-attribute :lisp-syntax c)
                        until (not (eq attr :prefix))
                        do (editor::point-after start)
                        finally (return attr))))
        (when (eq attr :open-paren)
          (progn
            (editor:form-offset start 1 t -1)
            (editor:move-point end start)
            (let ((children (loop do (unless (editor:form-offset end 1 t 0)
                                       (loop-finish))
                                     (editor:move-point start end)
                                     (editor:form-offset start -1 t 0)
                               collect (list (editor:copy-point start :temporary)
                                             (editor:copy-point end :temporary)))))
              (when children (fontify-declaration-list children)))))))))

(defun fontify-list (start &optional end)
  (declare (ignore end))
  (editor:with-point ((form-start start)
                      (form-end start))
    (editor:form-offset form-start 1 t -1)
    (editor:move-point form-end form-start)
    (let ((forms (loop do (unless (editor:form-offset form-end 1 t 0)
                            (loop-finish))
                          (editor:move-point form-start form-end)
                          (editor:form-offset form-start -1 t 0)
                       collect (list (editor:copy-point form-start :temporary)
                                     (editor:copy-point form-end :temporary)))))
      (when forms
        (cond ((member (apply #'editor:points-to-string (first forms))
                       '("declare" "proclaim" "declaim")
                       :test #'string-equal)
               (fontify-declaration-list forms))
              (t
               (dolist (l forms)
                 (apply #'fontify-single-form l))))))))

;;; END

;;; Main Function

(defun fontify-keywords-region (start end)
  (editor:with-buffer-locked ((editor:point-buffer start) :for-modification nil)
    (editor::with-point ((form-start start)
                         (form-end start))
      (loop (unless (editor:form-offset form-end 1 t 0)
              (return))
            (editor:move-point form-start form-end)
            (editor:form-offset form-start -1 t 0)
            (fontify-single-form form-start form-end)
            (when (editor:point> form-end end) (return))))))

;;; END

;;; Editor Mode Definition

(editor:defmode "Colourful"
  :vars '((editor::font-lock-fontify-keywords-region-function . fontify-keywords-region))
  :setup-function #'(lambda (buffer)
                      (when (editor::buffer-font-lock-mode-p buffer)
                        (editor::font-lock-fontify-buffer buffer))))

(setf (editor:variable-value 'editor::font-lock-fontify-by-default :mode "Colourful") t)

(editor:add-global-hook editor::markdown-mode-hook #'editor:turn-on-font-lock)

(editor:defcommand "Colourful Mode" (p)
     "Toggle Colourful Mode"
     "Enable Colourful mode when `p' is positive, otherwise disable it.
toggle the mode when `p' is nil."
  (let ((buffer (editor:current-buffer)))
    (setf (editor:buffer-minor-mode buffer "Colourful")
          (if p (plusp p) (not (editor:buffer-minor-mode buffer "Colourful"))))))

(editor:define-file-type-hook
    ("lispworks" "lisp" "slisp" "l" "lsp" "mcl" "cl")
    (buffer type)
  (declare (ignore type))
  (setf (editor:buffer-major-mode buffer) "Lisp")
  (setf (editor:buffer-minor-mode buffer "Colourful") t))

;;; END
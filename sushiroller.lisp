;;;; sushiroller.lisp

(in-package #:sushiroller)

(defvar *current-line* 0)
(defvar *void-tags* '(:area :base :br :col :embed :hr :img :link :meta :param :source :track :wbr))

(defclass/std node ()
  ((name :std (make-array 8 :element-type 'character :fill-pointer 0 :adjustable t))
   (attributes children classes :std (make-array 8 :fill-pointer 0 :adjustable t))))

(defclass/std executable ()
  ((code :std (list))
   (manual-printing-p)))

(defun read-executable (stream)
  (let ((manual-printing-p (eq (peek-char t stream) #\@)))
    (when manual-printing-p (read-char stream))
    (make 'executable :code (read stream) :manual-printing-p manual-printing-p)))

(defun read-next-sexp (stream)
  (let ((character-mark (peek-char t stream)))
    (case character-mark
      (#\quotation_mark (read stream))
      (#\@ (read-char stream nil) (read-executable stream))
      (#\left_parenthesis (read-char stream nil) (read-list stream))
      (#\; (read-line stream) (read-next-sexp stream))
      (otherwise (error (format nil "Unexpected `~C'" character-mark))))))

(defun read-identifier (stream)
  "Returns a list: (`identifier' `continue-reading-p')"
  (let ((output-string (make-array 10 :element-type 'character :adjustable t :fill-pointer 0)))
    (do* ((char (read-char stream) (read-char stream))
          (white-char-p (rtl:white-char-p char) (rtl:white-char-p char)))
         ((or white-char-p (member char '(#\@ #\quotation_mark #\( #\) #\. #\#)))
          (unless white-char-p (unread-char char stream))
          (list output-string (member char '(#\. #\#))))
      (pushx char output-string))))

(defun read-list (stream)
  (let ((elem (make 'node)))
    (peek-char t stream)
    (do ((previous-separator :initial))
        ((null previous-separator))
      (destructuring-bind (identifier next-separator-list) (read-identifier stream)
        (if (eq previous-separator :initial)
            (setf (name elem) identifier)
            (if (eq previous-separator #\.)
                (pushx (format nil "~A" identifier) (classes elem))
                (pushx `(:id ,identifier) (attributes elem))))
        (setf previous-separator (car next-separator-list))
        (when previous-separator (read-char stream))))
    (do ((char (peek-char t stream) (peek-char t stream)))
        ((eq char #\right_parenthesis) (read-char stream) elem)
      (case char
        (#\colon (pushx (list (read stream) (read-next-sexp stream)) (attributes elem)))
        (otherwise (pushx (read-next-sexp stream) (children elem)))))))

(defun generate-flat-list (stack)
  (let ((output-stack (make-array 8 :fill-pointer 0 :adjustable t)))
    (rtl:dovec (node stack)
      (typecase node
        (node
         (pushx (format nil "<~A~@[ class=\"~{~A~^ ~}\"~]"
                        (name node) (map 'list #'identity (classes node)))
                output-stack)
         (rtl:dovec (attribute (attributes node))
           (pushx (format nil " ~(~A~)=\"" (car attribute)) output-stack)
           (typecase (cadr attribute)
             (string (pushx (format nil "~A\"" (cadr attribute)) output-stack))
             (executable (pushx (cadr attribute) output-stack) (pushx "\"" output-stack))))
         (pushx ">" output-stack)
         (rtl:dovec (child (generate-flat-list (children node)))
           (pushx child output-stack))
         (unless (member (name node) *void-tags* :test #'string-equal)
           (pushx (format nil "</~A>" (name node)) output-stack)))
        (t (pushx node output-stack))))
    output-stack))

(defmethod executable-rendering-sexp ((e executable) (stream-var symbol))
  (if (manual-printing-p e)
      (code e)
      `(format ,stream-var "~A" ,(code e))))

(defvar *output-stream* nil)
(defvar *activated-p* nil)

(defun generate-renderer (stream)
  (let ((stack (generate-flat-list (rtl:vec (read-next-sexp stream))))
        (output-expressions (list)))
    (rtl:dovec (node stack (nreverse output-expressions))
      (typecase node
        (executable (push (executable-rendering-sexp node '*output-stream*) output-expressions))
        (string
         (typecase (car output-expressions)
           (string
            (setf (car output-expressions) (concatenate 'string (car output-expressions) node)))
           (list
            (push node output-expressions))))))))

(defun roll (stream subchar &optional arg)
  (declare (ignore subchar arg))
  (rtl:with-gensyms (fun)
    `(flet ((,fun ()
              ,@(map 'list
                 (lambda (item)
                   (if (listp item) item `(format *output-stream* "~A" ,item)))
                 (generate-renderer stream))))
       (if *output-stream*
           (progn (,fun))
           (with-output-to-string (*output-stream*)
             (,fun))))))

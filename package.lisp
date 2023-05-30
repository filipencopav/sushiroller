;;;; package.lisp

(defpackage #:sushiroller
  (:use #:cl)
  (:import-from #:defclass-std #:defclass/std)
  (:import-from #:rutils.abbr #:pushx #:make)
  (:export :sushiroller :roll))

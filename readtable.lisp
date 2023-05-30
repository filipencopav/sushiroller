(in-package :sushiroller)

(named-readtables:defreadtable sushiroller:sushiroller
  (:merge :standard)
  (:dispatch-macro-char #\# #\@ #'roll))

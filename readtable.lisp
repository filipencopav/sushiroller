(in-package :sushiroller)

(named-readtables:defreadtable sushiroller:sushiroller
  (:merge :current)
  (:dispatch-macro-char #\# #\@ #'roll))

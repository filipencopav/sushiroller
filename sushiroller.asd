;;;; sushiroller.asd

(asdf:defsystem #:sushiroller
  :description "Describe sushiroller here"
  :author "Your Name <your.name@example.com>"
  :license  "Specify license here"
  :version "0.0.1"
  :serial t
  :depends-on (#:rutils #:defclass-std)
  :components ((:file "package")
               (:file "sushiroller")))

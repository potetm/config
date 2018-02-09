(ns com.potetm.aot-compile
  (:require [clojure.tools.namespace.find :as ns-find]
            [clojure.java.classpath :as jcp]))

(assert (= 1
           (count *command-line-args*))
        "aot compilation requires a single target path argument")

(binding [clojure.core/*compile-path* (first *command-line-args*)
          clojure.core/*compiler-options* {:direct-linking true}]
  (doseq [n (ns-find/find-namespaces (jcp/classpath-directories))]
    (println "compiling:" n)
    (compile n)))


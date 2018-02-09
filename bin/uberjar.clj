(ns com.potetm.uberjar
  (:require [clojure.tools.deps.alpha :as deps]
            [clojure.tools.deps.alpha.reader :as deps-rdr]
            [clojure.java.io :as io]

            ;; Load extensions
            [clojure.tools.deps.alpha.extensions.maven]
            [clojure.tools.deps.alpha.extensions.local]
            [clojure.tools.deps.alpha.extensions.git]
            [clojure.tools.deps.alpha.extensions.deps])
  (:import (java.util.zip ZipEntry
                          ZipFile
                          ZipOutputStream)
           (java.nio.file Files
                          FileVisitOption
                          LinkOption
                          OpenOption
                          Path
                          StandardOpenOption)
           (java.nio.file.attribute FileAttribute)
           (java.io File)))

(defn -main
  "Create an uberjar at 'target' using deps in ./deps.edn and
  provided 'src-files'.

  src-files must be provided to allow for aot compilation at a
  location other that :paths defined in deps.edn."
  [& [target & src-files]]
  (let [target (.toPath (io/file target))
        ;; Java throws exception on dup entries; skip manually.
        entries (volatile! #{})]
    (Files/createDirectories (.getParent target)
                             (make-array FileAttribute 0))
    (with-open [out (ZipOutputStream.
                      (Files/newOutputStream target
                        (into-array OpenOption
                                    [StandardOpenOption/CREATE])))]

      (println "Adding project sources to uberjar.")
      (doseq [src (map (comp #(.toPath ^File %)
                             io/file)
                       src-files)]
        (with-open [ps (Files/walk src
                                   (into-array FileVisitOption
                                               [FileVisitOption/FOLLOW_LINKS]))]
          (doseq [^Path p (iterator-seq (.iterator ps))]
            (let [es @entries
                  n (str (.relativize src p)
                         (if (Files/isDirectory p
                                                (make-array LinkOption 0))
                           "/"))]
              (when (and (not (contains? es n))
                         (not= "/" n))
                (.putNextEntry out
                               (doto (ZipEntry. n)
                                 (.setTime (.toMillis (Files/getLastModifiedTime
                                                        p
                                                        (make-array LinkOption 0))))))
                (when-not (Files/isDirectory p
                                             (make-array LinkOption 0))
                  (Files/copy p out))
                (.closeEntry out)
                (vswap! entries conj n))))))

      ;; Never include external index.list.
      (vswap! entries conj "META-INF/INDEX.LIST")

      ;; write deps
      (println "Adding deps to uberjar.")
      (doseq [[dep p] (mapcat (fn [[dep {ps :paths}]]
                                ;; we want the dep w/ every path for that dep
                                ;; for feedback
                                (map (fn [p]
                                       [dep p])
                                     ps))
                              (deps/resolve-deps (deps-rdr/read-deps [(io/file "./deps.edn")])
                                                  nil))]
        (println "Adding:" dep)
        (with-open [zf (ZipFile. p)]
          (doseq [e (enumeration-seq (.entries zf))]
            (let [es @entries
                  n (.getName e)]
              (when-not (contains? es n)
                (.putNextEntry out e)
                (when-not (.isDirectory e)
                  (io/copy (.getInputStream zf e)
                           out))
                (.closeEntry out)
                (vswap! entries conj n)))))))))

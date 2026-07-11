;;; malyon-praxix-test.el --- praxix conformance test for malyon -*- lexical-binding: t; -*-

;; Praxix is a second self-checking Z-code conformance suite. Unlike czech it is
;; menu-driven: send "all" to run every section, then "quit". Each section prints
;; "Passed." or "N tests failed", and the run ends with an overall summary.
;;
;; It is compiled to versions 5 and 8 (praxix uses v5+ features, so there is no
;; v3 build). Two things are asserted for each:
;;  - praxix runs to completion without crashing the interpreter. This guards the
;;    crashes already fixed (signed array indices in loadw/loadb/storew/storeb,
;;    and get_prop_len 0), either of which aborted the run mid-suite.
;;  - praxix reports every section passing. The Z-Machine 1.1/1.2 sections
;;    self-skip because malyon advertises Standard 1.0, so they are not failures.

;;; Code:

(require 'ert)
(require 'malyon-harness (expand-file-name "malyon-harness.el"
                                           (file-name-directory
                                            (or load-file-name buffer-file-name))))

(defvar malyon-praxix-dir
  (file-name-directory (or load-file-name buffer-file-name)))

(defun malyon-praxix--run (version)
  "Run praxix for VERSION through every test and return its transcript."
  (plist-get (malyon-harness-run
              (expand-file-name (format "fixtures/praxix.z%d" version)
                                malyon-praxix-dir)
              '("all" "quit" "quit"))
             :transcript))

(defun malyon-praxix--check-version (version)
  "Run praxix for VERSION and assert it completes with every section passing."
  (let ((transcript (malyon-praxix--run version)))
    ;; A crash would abort before the goodbye and summary lines.
    (should (string-match-p "Goodbye\\." transcript))
    (should (string-match-p "All tests passed" transcript))
    (should-not (string-match-p "tests failed overall" transcript))))

(ert-deftest malyon-praxix-v5 ()
  "praxix.z5 (version 5) passes every section."
  (malyon-praxix--check-version 5))

(ert-deftest malyon-praxix-v8 ()
  "praxix.z8 (version 8) passes every section."
  (malyon-praxix--check-version 8))

;;; malyon-praxix-test.el ends here

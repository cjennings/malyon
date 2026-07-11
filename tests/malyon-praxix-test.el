;;; malyon-praxix-test.el --- praxix conformance test for malyon -*- lexical-binding: t; -*-

;; Praxix is a second self-checking Z-code conformance suite. Unlike czech it is
;; menu-driven: send "all" to run every section, then "quit". Each section prints
;; "Passed." or "N tests failed", and the run ends with an overall summary.
;;
;; Two things are asserted:
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

(defvar malyon-praxix-story
  (expand-file-name "fixtures/praxix.z5"
                    (file-name-directory (or load-file-name buffer-file-name))))

(defun malyon-praxix--run ()
  "Run praxix through every test and return its transcript."
  (plist-get (malyon-harness-run malyon-praxix-story '("all" "quit" "quit"))
             :transcript))

(ert-deftest malyon-praxix-runs-to-completion ()
  "praxix runs every section and reaches its goodbye without crashing."
  (let ((transcript (malyon-praxix--run)))
    (should (string-match-p "Goodbye\\." transcript))
    ;; A crash would abort before the overall summary line is printed.
    (should (string-match-p "tests failed overall\\|All tests passed" transcript))))

(ert-deftest malyon-praxix-all-pass ()
  "praxix reports every section passing (no failures overall)."
  (let ((transcript (malyon-praxix--run)))
    (should (string-match-p "All tests passed" transcript))
    (should-not (string-match-p "tests failed overall" transcript))))

;;; malyon-praxix-test.el ends here

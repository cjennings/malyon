;;; malyon-praxix-test.el --- praxix conformance test for malyon -*- lexical-binding: t; -*-

;; Praxix is a second self-checking Z-code conformance suite. Unlike czech it is
;; menu-driven: send "all" to run every section, then "quit". Each section prints
;; "Passed." or "N tests failed", and the run ends with an overall summary.
;;
;; Two things are asserted:
;;  - praxix runs to completion without crashing the interpreter. This guards the
;;    two crashes already fixed (signed array indices in loadw/loadb/storew/storeb,
;;    and get_prop_len 0), either of which aborted the run mid-suite.
;;  - the only failing sections are the known-open set. praxix reports failures in
;;    undo, multiundo, and streamtrip (memory-stream round-trip) — tracked bugs
;;    not yet fixed. If a currently-passing section regresses, or one of these is
;;    fixed, this baseline assertion fires so the expectation gets updated
;;    deliberately.

;;; Code:

(require 'ert)
(require 'malyon-harness (expand-file-name "malyon-harness.el"
                                           (file-name-directory
                                            (or load-file-name buffer-file-name))))

(defvar malyon-praxix-story
  (expand-file-name "fixtures/praxix.z5"
                    (file-name-directory (or load-file-name buffer-file-name))))

(defvar malyon-praxix-known-failing-sections '("undo" "multiundo" "streamtrip")
  "praxix sections with open, unfixed conformance bugs.
Shrink this as the bugs are fixed; the baseline test keys off it.")

(defun malyon-praxix--run ()
  "Run praxix through every test and return its transcript."
  (plist-get (malyon-harness-run malyon-praxix-story '("all" "quit" "quit"))
             :transcript))

(defun malyon-praxix--failing-sections (transcript)
  "Return the section names praxix reports as failing overall in TRANSCRIPT.
The summary line reads: \"N tests failed overall: undo (1), streamtrip (6).\""
  (when (string-match "tests failed overall:\\([^\n.]*\\)" transcript)
    (let ((tail (match-string 1 transcript)) (names '()) (start 0))
      (while (string-match "\\([a-z_]+\\) (" tail start)
        (push (match-string 1 tail) names)
        (setq start (match-end 0)))
      (nreverse names))))

(ert-deftest malyon-praxix-runs-to-completion ()
  "praxix runs every section and reaches its goodbye without crashing."
  (let ((transcript (malyon-praxix--run)))
    (should (string-match-p "Goodbye\\." transcript))
    ;; A crash would abort before the overall summary line is printed.
    (should (string-match-p "tests failed overall\\|All tests passed" transcript))))

(ert-deftest malyon-praxix-only-known-sections-fail ()
  "The only failing praxix sections are the known-open set."
  (let* ((transcript (malyon-praxix--run))
         (failing (malyon-praxix--failing-sections transcript)))
    (should (equal (sort (copy-sequence failing) #'string<)
                   (sort (copy-sequence malyon-praxix-known-failing-sections)
                         #'string<)))))

;;; malyon-praxix-test.el ends here

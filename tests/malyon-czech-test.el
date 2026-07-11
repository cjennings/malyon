;;; malyon-czech-test.el --- czech conformance test for malyon -*- lexical-binding: t; -*-

;; CZECH (Comprehensive Z-machine Emulation CHecker) is a self-checking Z-code
;; story file: it runs a battery of opcode tests, prints "Expected X; got Y" for
;; each failure, and ends by reporting "Passed: N, Failed: M" then quitting. It
;; needs no user input, which makes it the strongest headless conformance oracle
;; we have. We assert czech's own verdict rather than diffing the raw transcript,
;; because header/screen-size lines legitimately vary between interpreters.
;;
;; czech.inf is compiled to versions 3, 5, and 8 (the three malyon supports), so
;; the version-specific code paths — opcode encodings, object and property table
;; formats, addressing — are each exercised. The expected pass count differs per
;; version (v3 has fewer opcodes), but "reaches quit, zero failures, no crash" is
;; the same assertion across all three.

;;; Code:

(require 'ert)
(require 'malyon-harness (expand-file-name "malyon-harness.el"
                                           (file-name-directory
                                            (or load-file-name buffer-file-name))))

(defvar malyon-czech-dir
  (file-name-directory (or load-file-name buffer-file-name)))

(defun malyon-czech--story (version)
  "Return the path to the czech story file for VERSION (3, 5, or 8)."
  (expand-file-name (format "fixtures/czech.z%d" version) malyon-czech-dir))

(defun malyon-czech--failed-count (transcript)
  "Return czech's self-reported failure count from TRANSCRIPT, or nil if absent."
  (when (string-match "Passed: *\\([0-9]+\\), *Failed: *\\([0-9]+\\)" transcript)
    (string-to-number (match-string 2 transcript))))

(defun malyon-czech--failures (transcript)
  "Return the list of czech \"Expected ...; got ...\" failure lines in TRANSCRIPT."
  (let ((lines '()) (start 0))
    (while (string-match "\\[?[0-9]*\\]?[^\n]*Expected[^\n]*got[^\n]*" transcript start)
      (push (match-string 0 transcript) lines)
      (setq start (match-end 0)))
    (nreverse lines)))

(defun malyon-czech--check-version (version)
  "Run czech for VERSION and assert it completes with zero failures."
  (let* ((r (malyon-harness-run (malyon-czech--story version)))
         (transcript (plist-get r :transcript))
         (failed (malyon-czech--failed-count transcript)))
    ;; Ran to its @quit without crashing the interpreter.
    (should (string-match-p "Didn't crash: hooray!" transcript))
    (should (eq 'quit (plist-get r :status)))
    ;; Reached its summary line and reported no failures.
    (should failed)
    (when (and failed (> failed 0))
      (ert-fail (list (format "czech.z%d reported %d failure(s):" version failed)
                      (malyon-czech--failures transcript))))
    (should (= 0 failed))))

(ert-deftest malyon-czech-v3 ()
  "czech.z3 (version 3) passes every test."
  (malyon-czech--check-version 3))

(ert-deftest malyon-czech-v5 ()
  "czech.z5 (version 5) passes every test."
  (malyon-czech--check-version 5))

(ert-deftest malyon-czech-v8 ()
  "czech.z8 (version 8) passes every test."
  (malyon-czech--check-version 8))

;;; malyon-czech-test.el ends here

;;; malyon-czech-test.el --- czech conformance test for malyon -*- lexical-binding: t; -*-

;; CZECH (Comprehensive Z-machine Emulation CHecker) is a self-checking Z-code
;; story file: it runs ~425 opcode tests, prints "Expected X; got Y" for each
;; failure, and ends by reporting "Passed: N, Failed: M" then quitting. It needs
;; no user input, which makes it the strongest headless conformance oracle we
;; have. We assert czech's own verdict rather than diffing the raw transcript,
;; because header/screen-size lines legitimately vary between interpreters.

;;; Code:

(require 'ert)
(require 'malyon-harness (expand-file-name "malyon-harness.el"
                                           (file-name-directory
                                            (or load-file-name buffer-file-name))))

(defvar malyon-czech-story
  (expand-file-name "fixtures/czech.z5"
                    (file-name-directory (or load-file-name buffer-file-name))))

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

(ert-deftest malyon-czech-runs-to-completion ()
  "czech.z5 runs to its @quit without crashing the interpreter."
  (let ((r (malyon-harness-run malyon-czech-story)))
    (should (string-match-p "Didn't crash: hooray!" (plist-get r :transcript)))
    (should (eq 'quit (plist-get r :status)))))

(ert-deftest malyon-czech-zero-failures ()
  "czech.z5 reports zero failed opcode tests."
  (let* ((r (malyon-harness-run malyon-czech-story))
         (transcript (plist-get r :transcript))
         (failed (malyon-czech--failed-count transcript)))
    (should failed)                     ; czech reached its summary line
    (when (and failed (> failed 0))
      ;; Surface exactly which tests failed, so a red run is self-explaining.
      (ert-fail (list (format "czech reported %d failure(s):" failed)
                      (malyon-czech--failures transcript))))
    (should (= 0 failed))))

;;; malyon-czech-test.el ends here

;;; malyon-save-restore-test.el --- Quetzal save/restore tests -*- lexical-binding: t; -*-

;; The conformance suites (czech, praxix) never touch disk saves, so the Quetzal
;; save/restore path is otherwise untested. These tests drive a save then a
;; restore and assert the round-trip reproduces the machine state: dynamic
;; memory, the value stack, and the three pointers.

;;; Code:

(require 'ert)
(require 'malyon-harness (expand-file-name "malyon-harness.el"
                                           (file-name-directory
                                            (or load-file-name buffer-file-name))))

(defvar malyon-sr-story
  (expand-file-name "fixtures/czech.z5"
                    (file-name-directory (or load-file-name buffer-file-name))))

(defun malyon-sr--load ()
  "Load and initialize the czech story into a fresh interpreter state."
  (dolist (b '("Malyon Transcript" "Malyon Status"))
    (when (get-buffer b) (kill-buffer b)))
  (setq malyon-story-file nil
        malyon-transcript-buffer nil
        malyon-status-buffer nil
        malyon-window-configuration nil)
  (malyon-load-story-file malyon-sr-story)
  (setq malyon-story-version (aref malyon-story-file 0))
  (malyon-initialize))

(ert-deftest malyon-save-restore-quetzal-roundtrip ()
  "A Quetzal save then restore reproduces memory, stack, and pointers."
  (malyon-sr--load)
  (let ((tmp (make-temp-file "malyon-save" nil ".qzl")))
    (unwind-protect
        (progn
          ;; Build a distinctive state: writes into dynamic memory, a couple of
          ;; pushed stack words, and a moved instruction pointer.
          (malyon-store-byte 100 42)
          (malyon-store-byte 200 99)
          (malyon-push-stack 12345)
          (malyon-push-stack 54321)
          (setq malyon-instruction-pointer 5000)
          (let ((ip malyon-instruction-pointer)
                (sp malyon-stack-pointer)
                (fp malyon-frame-pointer)
                (stack (copy-sequence malyon-stack)))
            ;; Save returns 1 on success.
            (should (= 1 (malyon-save-file tmp)))
            ;; Clobber the live state so a no-op "restore" can't pass.
            (malyon-store-byte 100 0)
            (malyon-store-byte 200 0)
            (malyon-pop-stack)
            (setq malyon-instruction-pointer 0)
            ;; Restore returns 2 on success.
            (should (= 2 (malyon-restore-file tmp)))
            ;; Pointers and memory come back.
            (should (= ip malyon-instruction-pointer))
            (should (= sp malyon-stack-pointer))
            (should (= fp malyon-frame-pointer))
            (should (= 42 (malyon-read-byte 100)))
            (should (= 99 (malyon-read-byte 200)))
            (dotimes (i (1+ sp))
              (should (= (aref stack i) (aref malyon-stack i))))))
      (delete-file tmp))))

(ert-deftest malyon-restore-missing-file-returns-0 ()
  "Restoring from a nonexistent file fails cleanly with 0."
  (malyon-sr--load)
  (should (= 0 (malyon-restore-file
                (expand-file-name "does-not-exist.qzl"
                                  temporary-file-directory)))))

;;; malyon-save-restore-test.el ends here

;;; malyon-unit-test.el --- unit tests for malyon's pure helpers -*- lexical-binding: t; -*-

;; Fast, isolated tests for the self-contained helpers, exercised directly on
;; synthetic memory rather than through a story file. The conformance suites
;; cover these at the opcode level; these pin the primitives' Normal, Boundary,
;; and Error behavior so a regression is caught at its source.

;;; Code:

(require 'ert)
(require 'malyon (expand-file-name
                  "malyon.el"
                  (file-name-directory
                   (directory-file-name
                    (file-name-directory (or load-file-name buffer-file-name))))))

;;; malyon-number — unsigned 16-bit to signed.

(ert-deftest malyon-number-normal ()
  (should (= 0 (malyon-number 0)))
  (should (= 100 (malyon-number 100)))
  (should (= 32767 (malyon-number 32767))))

(ert-deftest malyon-number-boundary ()
  ;; 0x8000 is the first negative value; 0xFFFF is -1.
  (should (= -32768 (malyon-number 32768)))
  (should (= -1 (malyon-number 65535))))

;;; Memory primitives on synthetic story memory.

(defmacro malyon-unit--with-memory (size &rest body)
  "Run BODY with `malyon-story-file' bound to a fresh zeroed vector of SIZE."
  (declare (indent 1))
  `(let ((malyon-story-file (make-vector ,size 0)))
     ,@body))

(ert-deftest malyon-store-read-byte-roundtrip ()
  (malyon-unit--with-memory 16
    (malyon-store-byte 5 200)
    (should (= 200 (malyon-read-byte 5)))))

(ert-deftest malyon-store-byte-masks-to-8-bits ()
  (malyon-unit--with-memory 16
    ;; 0x1FF should truncate to 0xFF.
    (malyon-store-byte 3 511)
    (should (= 255 (malyon-read-byte 3)))))

(ert-deftest malyon-store-read-word-roundtrip ()
  (malyon-unit--with-memory 16
    (malyon-store-word 4 #xBEEF)
    (should (= #xBEEF (malyon-read-word 4)))))

(ert-deftest malyon-read-word-is-big-endian ()
  (malyon-unit--with-memory 16
    (malyon-store-byte 8 #x12)
    (malyon-store-byte 9 #x34)
    (should (= #x1234 (malyon-read-word 8)))))

(ert-deftest malyon-store-word-masks-to-16-bits ()
  (malyon-unit--with-memory 16
    ;; 0x1BEEF should keep only the low 16 bits.
    (malyon-store-word 2 #x1BEEF)
    (should (= #xBEEF (malyon-read-word 2)))))

;;; malyon-string encode/decode round-trip via the ZSCII text primitives is
;;; covered by the czech print tests; the memory primitives above are the layer
;;; those build on.

;;; malyon-unit-test.el ends here

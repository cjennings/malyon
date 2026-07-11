;;; malyon-harness.el --- headless driver for testing malyon -*- lexical-binding: t; -*-

;; A test-support library, not a test file. It drives the malyon interpreter
;; without an interactive user so story files can be run in `emacs --batch' and
;; their transcript captured for comparison.
;;
;; malyon is event-driven: `malyon-execute' runs opcodes until an input opcode
;; installs a buffer keymap and throws `malyon-end-of-interpreter-loop', handing
;; control back to Emacs's command loop. Interactively a keymap command
;; (`malyon-end-input' for a line, `malyon-wait-char' for a key) resumes it. The
;; harness stands in for that command loop: it catches each throw, injects the
;; next scripted command, and resumes, collecting the transcript buffer text.

;;; Code:

(require 'malyon (expand-file-name "malyon.el"
                                   (file-name-directory
                                    (directory-file-name
                                     (file-name-directory
                                      (or load-file-name buffer-file-name))))))

(defvar malyon-harness-max-turns 500
  "Safety cap on resume cycles, so a stuck game can't loop forever.")

(defun malyon-harness--reset ()
  "Tear down any prior malyon session so a run starts from clean state."
  (setq malyon-story-file nil)
  (dolist (name '("Malyon Transcript" "Malyon Status"))
    (when (get-buffer name)
      (kill-buffer name)))
  (setq malyon-transcript-buffer nil
        malyon-status-buffer nil
        malyon-window-configuration nil))

(defun malyon-harness--transcript ()
  "Return the current transcript buffer contents as a plain string.
`malyon-cleanup' (run on @quit) nils `malyon-transcript-buffer' but leaves the
\"Malyon Transcript\" buffer alive with its text, so fall back to the name."
  (let ((buf (or (and (buffer-live-p malyon-transcript-buffer)
                      malyon-transcript-buffer)
                 (get-buffer "Malyon Transcript"))))
    (if (buffer-live-p buf)
        (with-current-buffer buf
          (buffer-substring-no-properties (point-min) (point-max)))
      "")))

(defun malyon-harness--feed-line (command)
  "Insert COMMAND at the transcript prompt and resume via `malyon-end-input'.
Returns the throw value from the resumed interpreter run."
  (with-current-buffer malyon-transcript-buffer
    (goto-char (point-max))
    (insert command)
    (malyon-end-input)))

(defun malyon-harness-run (story-file &optional commands)
  "Load STORY-FILE, run it headless, and return a result plist.

COMMANDS is a list of input lines fed one per line-input request, in order.
When the game asks for input and COMMANDS is exhausted, the run stops.

The plist keys:
  :transcript  the full transcript buffer text
  :status      one of `quit', `input-starved', `char-starved', `crashed',
               `turn-cap', or `no-throw'
  :error       the error object when :status is `crashed', else nil
  :turns       number of resume cycles performed"
  (malyon-harness--reset)
  (let ((result-status 'no-throw)
        (err nil)
        (turns 0)
        (throw-val nil))
    (condition-case e
        (progn
          (malyon-load-story-file story-file)
          (setq malyon-story-version (aref malyon-story-file 0))
          (malyon-initialize)
          (setq throw-val
                (catch 'malyon-end-of-interpreter-loop
                  (malyon-execute)
                  'fell-through))
          ;; Resume loop: keep feeding input while the game asks for a line and
          ;; we still have commands to give.
          (catch 'done
            (while t
              (cond
               ((eq throw-val 'malyon-opcode-quit)
                (setq result-status 'quit) (throw 'done nil))
               ((eq throw-val 'malyon-waiting-for-character)
                (setq result-status 'char-starved) (throw 'done nil))
               ((eq throw-val 'malyon-waiting-for-input)
                (unless commands
                  (setq result-status 'input-starved) (throw 'done nil))
                (when (>= turns malyon-harness-max-turns)
                  (setq result-status 'turn-cap) (throw 'done nil))
                (setq turns (1+ turns))
                (setq throw-val (malyon-harness--feed-line (pop commands))))
               (t
                ;; fell-through or an unexpected value: the loop ended on its own
                (setq result-status 'no-throw) (throw 'done nil))))))
      (error (setq result-status 'crashed err e)))
    (list :transcript (malyon-harness--transcript)
          :status result-status
          :error err
          :turns turns)))

(provide 'malyon-harness)
;;; malyon-harness.el ends here

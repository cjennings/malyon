EMACS ?= emacs

# Test files are auto-discovered, so a new tests/malyon-*-test.el is picked up
# without editing this list.
TESTS := $(wildcard tests/malyon-*-test.el)
LOADTESTS := $(foreach f,$(TESTS),-l $(f))

.PHONY: test compile clean

## test — run the full ERT suite (unit, conformance, save/restore).
test:
	$(EMACS) -Q --batch -L . $(LOADTESTS) -f ert-run-tests-batch-and-exit

## compile — byte-compile with warnings treated as errors, so the build stays
## warning-free.
compile:
	$(EMACS) -Q --batch -L . \
	  --eval '(setq byte-compile-error-on-warn t)' \
	  -f batch-byte-compile malyon.el
	@rm -f malyon.elc

clean:
	rm -f malyon.elc tests/*.elc

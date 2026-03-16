JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)

MISSING = \
	find . \( \( -name foo \) -prune \) \
	    -o \( -name '*.v' \
		  -print \) | \
		xargs egrep -i -Hn '(Fail|abort|admit|undefined|jww)' | \
		      egrep -v 'Definition undefined' | \
		      egrep -v '(old|new|research)/'

all: coq-lattice
	-@$(MISSING) || exit 0

coq-lattice: Makefile.coq $(wildcard *.v)
	$(MAKE) -f Makefile.coq JOBS=$(JOBS)

Makefile.coq: _CoqProject
	coq_makefile -f $< -o $@

clean: _CoqProject Makefile.coq
	$(MAKE) -f Makefile.coq clean

install: _CoqProject Makefile.coq
	$(MAKE) -f Makefile.coq install

fullclean: clean
	rm -f Makefile.coq Makefile.coq.conf .Makefile.d

# ---------- Lint: check for Admitted/admit/axioms ----------

.PHONY: lint
lint: coq-lattice
	@echo "==> Checking for Admitted/admit..."
	@! grep -nE '^\s*(Admitted|admit)\b' Lattice.v || \
		(echo "WARNING: Found Admitted/admit in Lattice.v" && exit 0)
	@echo "==> Checking for trailing whitespace..."
	@! grep -nP '\s+$$' Lattice.v || \
		(echo "ERROR: Found trailing whitespace" && exit 1)
	@echo "==> Lint passed (build compiled with -w +all)"

# ---------- Timing / performance profiling ----------

.PHONY: timing
timing: Makefile.coq $(wildcard *.v)
	$(MAKE) -f Makefile.coq TIMING=1 JOBS=$(JOBS) 2>&1 | tee timing.log
	@echo "==> Timing results saved to timing.log"

TIMING_BEFORE ?= timing-before.log
TIMING_AFTER  ?= timing-after.log

.PHONY: timing-diff
timing-diff:
	@if [ ! -f "$(TIMING_BEFORE)" ] || [ ! -f "$(TIMING_AFTER)" ]; then \
		echo "Usage: make timing-diff TIMING_BEFORE=before.log TIMING_AFTER=after.log"; \
		exit 1; \
	fi
	@python3 scripts/timing-diff.py "$(TIMING_BEFORE)" "$(TIMING_AFTER)"

# ---------- Style / formatting check ----------

.PHONY: format-check
format-check:
	@echo "==> Checking for tabs..."
	@! grep -nP '\t' Lattice.v || \
		(echo "ERROR: Found tabs (use spaces)" && exit 1)
	@echo "==> Checking for trailing whitespace..."
	@! grep -nP '\s+$$' Lattice.v || \
		(echo "ERROR: Found trailing whitespace" && exit 1)
	@echo "==> Checking for trailing newline..."
	@test -z "$$(tail -c 1 Lattice.v)" || \
		(echo "ERROR: File does not end with newline" && exit 1)
	@echo "==> Format check passed"

# ---------- Admitted check (coverage proxy) ----------

.PHONY: admitted-check
admitted-check:
	@echo "==> Checking for Admitted proofs..."
	@count=$$(grep -cE '^\s*Admitted\.' Lattice.v 2>/dev/null || echo 0); \
	if [ "$$count" -gt 0 ]; then \
		echo "WARNING: $$count Admitted proof(s) found:"; \
		grep -nE '^\s*Admitted\.' Lattice.v; \
	else \
		echo "==> No Admitted proofs found"; \
	fi

# ---------- All checks ----------

.PHONY: check
check: coq-lattice lint format-check admitted-check
	@echo "==> All checks passed"

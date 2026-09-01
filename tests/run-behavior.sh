#!/usr/bin/env bash
# tests/run-behavior.sh — one module's behavior tests in a clean shell.
# called by lib/test.sh; not for direct use.

module="${1:?module name}"
export LAZY_ROOT="${LAZY_ROOT:?LAZY_ROOT required}"
export LAZY_CONFIG="${LAZY_CONFIG:-}"
export LAZY_MODULES="${LAZY_MODULES:-}"
export LAZY_TEST_FORCE_COLOR=1

# shellcheck source=/dev/null
. "${LAZY_ROOT}/lazy.sh"
# shellcheck source=/dev/null
. "${LAZY_ROOT}/lib/test.sh"
# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_init_colors

LAZY_TEST_TOTAL_FAILS=0
# shellcheck source=/dev/null
. "${LAZY_ROOT}/modules/${module}/${module}.test.sh"

exit "${LAZY_TEST_TOTAL_FAILS:-0}"

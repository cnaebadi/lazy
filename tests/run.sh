#!/usr/bin/env bash
# tests/run.sh — source this from the user's shell (after lazy.sh).
#
#   . /path/to/lazy.sh
#   . /path/to/tests/run.sh           # health / conflicts
#   . /path/to/tests/run.sh full      # + behavior (all modules)
#   . /path/to/tests/run.sh uninstall # uninstall tests only

if [ -z "${LAZY_ROOT:-}" ]; then
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    LAZY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    LAZY_ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
  else
    LAZY_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  fi
  # shellcheck source=/dev/null
  . "${LAZY_ROOT}/lazy.sh"
fi

# shellcheck source=/dev/null
. "${LAZY_ROOT}/lib/test.sh"

_lazy_test_mode="${LAZY_TEST_MODE:-}"
case "${0##*/}" in
  run.sh) _lazy_test_mode="${1:-${_lazy_test_mode}}" ;;
esac

if [ "$_lazy_test_mode" = "uninstall" ]; then
  lazy_test_init_colors
  LAZY_TEST_TOTAL_FAILS=0
  lazy_test_module_start "uninstall"
  # shellcheck source=/dev/null
  . "${LAZY_ROOT}/tests/uninstall.test.sh"
  printf '\n'
  if [ "$LAZY_TEST_TOTAL_FAILS" -eq 0 ]; then
    printf '%sall good%s\n' "$LAZY_TEST_GREEN" "$LAZY_TEST_RESET"
  else
    printf '%s%s failed%s\n' "$LAZY_TEST_RED" "$LAZY_TEST_TOTAL_FAILS" "$LAZY_TEST_RESET"
    exit 1
  fi
  unset _lazy_test_mode
  return 0 2>/dev/null || exit 0
fi

lazy_test_run_all "${_lazy_test_mode}"
unset _lazy_test_mode

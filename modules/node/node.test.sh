#!/usr/bin/env bash
# modules/node/node.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_node_pm() {
  local pm="$1"
  lazy_test_mock_reset

  lazy_test_mock_cmd "$pm" '
printf "%s\n" "$*" >> "$LAZY_TEST_MOCK_DIR/log/'"$pm"'"
exit 0
'

  export NODE_PACKAGE_MANAGER="$pm"

  ni >/dev/null 2>&1 || { lazy_test_line "node:${pm}:ni" fail "ni"; return 1; }

  case "$pm" in
    npm)
      lazy_test_assert_contains "node:${pm}:ni" "$(lazy_test_mock_last "$pm")" "install"
      nadd lodash >/dev/null 2>&1
      lazy_test_assert_contains "node:${pm}:nadd" "$(lazy_test_mock_last "$pm")" "install lodash"
      ;;
    yarn)
      lazy_test_assert_contains "node:${pm}:ni" "$(lazy_test_mock_last "$pm")" "install"
      nadd lodash >/dev/null 2>&1
      lazy_test_assert_contains "node:${pm}:nadd" "$(lazy_test_mock_last "$pm")" "add lodash"
      ;;
    pnpm)
      lazy_test_assert_contains "node:${pm}:ni" "$(lazy_test_mock_last "$pm")" "install"
      nadd lodash >/dev/null 2>&1
      lazy_test_assert_contains "node:${pm}:nadd" "$(lazy_test_mock_last "$pm")" "add lodash"
      ;;
    bun)
      lazy_test_assert_contains "node:${pm}:ni" "$(lazy_test_mock_last "$pm")" "install"
      nadd lodash >/dev/null 2>&1
      lazy_test_assert_contains "node:${pm}:nadd" "$(lazy_test_mock_last "$pm")" "add lodash"
      ;;
  esac

  nr lint >/dev/null 2>&1
  case "$pm" in
    yarn) lazy_test_assert_contains "node:${pm}:nr" "$(lazy_test_mock_last "$pm")" "lint" ;;
    pnpm) lazy_test_assert_contains "node:${pm}:nr" "$(lazy_test_mock_last "$pm")" "run lint" ;;
    bun) lazy_test_assert_contains "node:${pm}:nr" "$(lazy_test_mock_last "$pm")" "run lint" ;;
    *) lazy_test_assert_contains "node:${pm}:nr" "$(lazy_test_mock_last "$pm")" "run lint" ;;
  esac

  nrd >/dev/null 2>&1
  nrb >/dev/null 2>&1
  nt >/dev/null 2>&1
  nout >/dev/null 2>&1

  lazy_test_assert_fail "node:${pm}:nr-missing" nr
  lazy_test_assert_fail "node:${pm}:nadd-missing" nadd
  return 0
}

lazy_test_node_full() {
  lazy_test_node_pm npm || return
  lazy_test_node_pm yarn || return
  lazy_test_node_pm pnpm || return
  lazy_test_node_pm bun || return
}

lazy_test_node_full

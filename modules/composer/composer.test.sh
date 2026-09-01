#!/usr/bin/env bash
# modules/composer/composer.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_composer_full() {
  lazy_test_mock_reset

  lazy_test_mock_cmd composer '
printf "%s\n" "$*" >> "$LAZY_TEST_MOCK_DIR/log/composer"
exit 0
'

  cins >/dev/null 2>&1 || { lazy_test_line "composer:cins" fail "cins"; return; }
  lazy_test_assert_contains "composer:cins" "$(lazy_test_mock_last composer)" "install"

  cup >/dev/null 2>&1
  lazy_test_assert_contains "composer:cup" "$(lazy_test_mock_last composer)" "update"

  creq laravel/sanctum >/dev/null 2>&1 || { lazy_test_line "composer:creq" fail "creq"; return; }
  lazy_test_assert_contains "composer:creq" "$(lazy_test_mock_last composer)" "require laravel/sanctum"

  cdu >/dev/null 2>&1
  lazy_test_assert_contains "composer:cdu" "$(lazy_test_mock_last composer)" "dump-autoload"

  crun test >/dev/null 2>&1 || { lazy_test_line "composer:crun" fail "crun"; return; }
  lazy_test_assert_contains "composer:crun" "$(lazy_test_mock_last composer)" "run-script test"

  lazy_test_assert_fail "composer:creq-missing" creq
  lazy_test_assert_fail "composer:crun-missing" crun
}

lazy_test_composer_full

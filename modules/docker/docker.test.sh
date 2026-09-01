#!/usr/bin/env bash
# modules/docker/docker.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_docker_mock() {
  lazy_test_mock_cmd docker '
log="$LAZY_TEST_MOCK_DIR/log/docker"
printf "%s\n" "$*" >> "$log"
case "$1" in
  compose)
    exit 0
    ;;
  ps)
    if [ "$2" = "--format" ]; then
      case "${LAZY_TEST_DOCKER_PS:-}" in
        solo) printf "solo\n" ;;
        multi) printf "a\nb\n" ;;
        *) : ;;
      esac
    fi
    exit 0
    ;;
  exec) exit 0 ;;
  *) exit 0 ;;
esac
'
}

lazy_test_docker_full() {
  lazy_test_mock_reset
  lazy_test_docker_mock
  export DOCKER_COMPOSE_FILE=docker-compose.yml
  export LAZY_TEST_DOCKER_PS=""

  dps -a >/dev/null 2>&1 || { lazy_test_line "docker:dps" fail "dps"; return; }
  lazy_test_assert_contains "docker:dps-args" "$(lazy_test_mock_last docker)" "ps -a"

  dcu >/dev/null 2>&1 || { lazy_test_line "docker:dcu" fail "dcu"; return; }
  lazy_test_assert_contains "docker:dcu-file" "$(lazy_test_mock_last docker)" "compose -f docker-compose.yml up -d"

  dcu prod.yml --build >/dev/null 2>&1 || { lazy_test_line "docker:dcu-override" fail "dcu override"; return; }
  lazy_test_assert_contains "docker:dcu-override" "$(lazy_test_mock_last docker)" "compose -f prod.yml up -d --build"

  dcd >/dev/null 2>&1 || { lazy_test_line "docker:dcd" fail "dcd"; return; }
  lazy_test_assert_contains "docker:dcd" "$(lazy_test_mock_last docker)" "compose -f docker-compose.yml down"

  dcr web >/dev/null 2>&1 || { lazy_test_line "docker:dcr" fail "dcr"; return; }
  lazy_test_assert_contains "docker:dcr" "$(lazy_test_mock_last docker)" "compose -f docker-compose.yml restart web"

  dlogs >/dev/null 2>&1 || { lazy_test_line "docker:dlogs" fail "dlogs"; return; }
  lazy_test_assert_contains "docker:dlogs" "$(lazy_test_mock_last docker)" "compose -f docker-compose.yml logs -f"

  LAZY_TEST_DOCKER_PS=solo
  denter >/dev/null 2>&1 || { lazy_test_line "docker:denter-solo" fail "denter"; return; }
  lazy_test_assert_contains "docker:denter-solo" "$(lazy_test_mock_last docker)" "exec -it solo sh"

  LAZY_TEST_DOCKER_PS=""
  lazy_test_assert_fail "docker:denter-none" denter

  LAZY_TEST_DOCKER_PS=multi
  lazy_test_assert_fail "docker:denter-multi" denter
}

lazy_test_docker_full

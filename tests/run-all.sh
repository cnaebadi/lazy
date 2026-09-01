#!/usr/bin/env bash
# tests/run-all.sh — CI / pre-push: health + full + uninstall
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
export LAZY_TEST_FORCE_COLOR=1

run() {
  printf '\n======== %s ========\n' "$1"
  if bash --noprofile --norc -c "$2"; then
    printf 'OK: %s\n' "$1"
  else
    printf 'FAIL: %s\n' "$1"
    FAIL=$((FAIL + 1))
  fi
}

MODULES="git,docker,k8s,aws,node,composer"
CONF="${TMPDIR:-/tmp}/lazy-run-all.conf"
cat > "$CONF" <<EOF
LAZY_MODULES=${MODULES}
LAZY_UNALIAS=false
GIT_REMOTE=origin
EOF

run "health" "
  export LAZY_TEST_FORCE_COLOR=1
  export LAZY_CONFIG='${CONF}'
  export LAZY_MODULES='${MODULES}'
  . '${ROOT}/lazy.sh'
  . '${ROOT}/lib/test.sh'
  lazy_test_run_all
"

run "full" "
  export LAZY_TEST_FORCE_COLOR=1
  export LAZY_CONFIG='${CONF}'
  export LAZY_MODULES='${MODULES}'
  . '${ROOT}/lazy.sh'
  . '${ROOT}/lib/test.sh'
  lazy_test_run_all full
"

run "uninstall" "
  export LAZY_TEST_FORCE_COLOR=1
  export LAZY_ROOT='${ROOT}'
  export LAZY_CONFIG='${CONF}'
  . '${ROOT}/lib/test.sh'
  lazy_test_init_colors
  LAZY_TEST_TOTAL_FAILS=0
  lazy_test_module_start uninstall
  . '${ROOT}/tests/uninstall.test.sh'
  [ \"\${LAZY_TEST_TOTAL_FAILS:-0}\" -eq 0 ]
"

run "zsh health" "
  export LAZY_TEST_FORCE_COLOR=1
  export LAZY_CONFIG='${CONF}'
  export LAZY_MODULES='${MODULES}'
  zsh -f -c '
    export LAZY_TEST_FORCE_COLOR=1
    . \"${ROOT}/lazy.sh\"
    . \"${ROOT}/lib/test.sh\"
    lazy_test_run_all
  '
"

if [ "$FAIL" -gt 0 ]; then
  printf '\n%d suite(s) failed\n' "$FAIL"
  exit 1
fi

printf '\nall suites passed\n'

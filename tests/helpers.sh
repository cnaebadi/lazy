#!/usr/bin/env bash
# tests/helpers.sh — mocks + assertions for behavior tests.
# source after lazy.sh + lib/test.sh

lazy_test_mock_reset() {
  LAZY_TEST_MOCK_DIR="${TMPDIR:-/tmp}/lazy-mock-$$"
  rm -rf "$LAZY_TEST_MOCK_DIR"
  mkdir -p "$LAZY_TEST_MOCK_DIR/log"
  export LAZY_TEST_MOCK_DIR

  local tool
  for tool in docker docker-compose kubectl aws npm yarn pnpm bun composer git; do
    unalias "$tool" 2>/dev/null || true
  done
  hash -r 2>/dev/null || true
  if [ -n "${ZSH_VERSION:-}" ]; then
    rehash 2>/dev/null || true
  fi

  export PATH="${LAZY_TEST_MOCK_DIR}:${PATH}"
}

lazy_test_mock_cmd() {
  # lazy_test_mock_cmd git 'echo "$@" >> "$LAZY_TEST_MOCK_DIR/log/git"'
  local name="$1"
  local body="$2"
  cat > "${LAZY_TEST_MOCK_DIR}/${name}" <<EOF
#!/usr/bin/env bash
${body}
EOF
  chmod +x "${LAZY_TEST_MOCK_DIR}/${name}"
}

lazy_test_mock_log() {
  local name="$1"
  printf '%s' "${LAZY_TEST_MOCK_DIR}/log/${name}"
}

lazy_test_mock_last() {
  local file
  file="$(lazy_test_mock_log "$1")"
  if [ -f "$file" ]; then
    tail -n 1 "$file"
  fi
}

lazy_test_mock_count() {
  local file
  file="$(lazy_test_mock_log "$1")"
  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    printf '0'
  fi
}

lazy_test_assert_contains() {
  local label="$1"
  local haystack="$2"
  local needle="$3"
  case "$haystack" in
    *"$needle"*) lazy_test_line "$label" ok ;;
    *) lazy_test_line "$label" fail "missing: $needle" ;;
  esac
}

lazy_test_assert_eq() {
  local label="$1"
  local got="$2"
  local want="$3"
  if [ "$got" = "$want" ]; then
    lazy_test_line "$label" ok
  else
    lazy_test_line "$label" fail "got '$got' want '$want'"
  fi
}

lazy_test_assert_fail() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    lazy_test_line "$label" fail "expected failure"
  else
    lazy_test_line "$label" ok
  fi
}

#!/usr/bin/env bash
# tests/uninstall.test.sh — uninstall behavior coverage

lazy_test_uninstall_full() {
  local tmp rc conf prefix src
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/lazy-uninstall-test.XXXXXX")" || {
    lazy_test_line "uninstall:init" fail "mktemp"
    return
  }

  rc="${tmp}/rc"
  conf="${tmp}/lazy.conf"
  prefix="${tmp}/install"
  src="${LAZY_ROOT}"

  mkdir -p "$prefix"
  cp "${src}/lazy.sh" "$prefix/"
  cp -R "${src}/lib" "${src}/modules" "${src}/config" "${src}/tests" "$prefix/"

  cat > "$rc" <<EOF
# before
export FOO=bar

# >>> lazy >>>
[ -f "${prefix}/lazy.sh" ] && . "${prefix}/lazy.sh"
# <<< lazy <<<

# after
EOF

  printf 'LAZY_MODULES=git\nGIT_REMOTE=origin\n' > "$conf"

  LAZY_YES=1 LAZY_RC="$rc" LAZY_CONFIG="$conf" LAZY_PREFIX="$prefix" \
    LAZY_UNINSTALL_RM_CONFIG=N LAZY_UNINSTALL_RM_PREFIX=N \
    bash "${src}/uninstall.sh" -y >/dev/null 2>&1 || {
    lazy_test_line "uninstall:run" fail "script failed"
    rm -rf "$tmp"
    return
  }

  if grep -q '>>> lazy >>>' "$rc" 2>/dev/null; then
    lazy_test_line "uninstall:rc-clean" fail "block remains"
  else
    lazy_test_line "uninstall:rc-clean" ok
  fi

  if grep -q 'before' "$rc" && grep -q 'after' "$rc"; then
    lazy_test_line "uninstall:rc-preserve" ok
  else
    lazy_test_line "uninstall:rc-preserve" fail "other lines lost"
  fi

  if [ -f "$conf" ]; then
    lazy_test_line "uninstall:config-kept" ok
  else
    lazy_test_line "uninstall:config-kept" fail "config deleted by default"
  fi

  if [ -d "$prefix" ]; then
    lazy_test_line "uninstall:prefix-kept" ok
  else
    lazy_test_line "uninstall:prefix-kept" fail "prefix deleted by default"
  fi

  # restore block + delete config when asked
  cat > "$rc" <<EOF
# >>> lazy >>>
[ -f "${prefix}/lazy.sh" ] && . "${prefix}/lazy.sh"
# <<< lazy <<<
EOF
  printf 'LAZY_MODULES=git\n' > "$conf"

  LAZY_YES=1 LAZY_RC="$rc" LAZY_CONFIG="$conf" LAZY_PREFIX="$prefix" \
    LAZY_UNINSTALL_RM_CONFIG=Y LAZY_UNINSTALL_RM_PREFIX=N \
    bash "${src}/uninstall.sh" -y >/dev/null 2>&1 || {
    lazy_test_line "uninstall:rm-config" fail "script failed"
    rm -rf "$tmp"
    return
  }

  if [ ! -f "$conf" ]; then
    lazy_test_line "uninstall:rm-config" ok
  else
    lazy_test_line "uninstall:rm-config" fail "config still exists"
  fi

  rm -rf "$tmp"
}

lazy_test_uninstall_full

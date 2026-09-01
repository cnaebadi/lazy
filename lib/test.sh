#!/usr/bin/env bash
# lib/test.sh — health + conflict checks for public lazy commands.
# source this; don't run it. install.sh will `. tests/run.sh` in the user's shell
# so leftover aliases are actually visible.

lazy_test_init_colors() {
  if [ -t 1 ] || [ "${LAZY_TEST_FORCE_COLOR:-}" = "1" ]; then
    LAZY_TEST_GREEN="$(printf '\033[32m')"
    LAZY_TEST_RED="$(printf '\033[31m')"
    LAZY_TEST_YELLOW="$(printf '\033[33m')"
    LAZY_TEST_DIM="$(printf '\033[2m')"
    LAZY_TEST_RESET="$(printf '\033[0m')"
  else
    LAZY_TEST_GREEN=""
    LAZY_TEST_RED=""
    LAZY_TEST_YELLOW=""
    LAZY_TEST_DIM=""
    LAZY_TEST_RESET=""
  fi
}

# What would actually run if the user typed $1 right now?
lazy_cmd_kind() {
  local name="$1"

  if [ -n "${BASH_VERSION:-}" ]; then
    local kind
    kind="$(type -t "$name" 2>/dev/null || true)"
    printf '%s' "${kind:-none}"
    return
  fi

  if [ -n "${ZSH_VERSION:-}" ]; then
    local w
    w="$(whence -w "$name" 2>/dev/null || true)"
    case "$w" in
      *': alias') printf 'alias' ;;
      *': function') printf 'function' ;;
      *': builtin') printf 'builtin' ;;
      *': command'|*': hashed') printf 'file' ;;
      *': reserved') printf 'keyword' ;;
      *) printf 'none' ;;
    esac
    return
  fi

  printf 'none'
}

# Binary on PATH, ignoring functions/aliases.
lazy_cmd_path() {
  local name="$1"
  if [ -n "${BASH_VERSION:-}" ]; then
    type -P "$name" 2>/dev/null || true
  else
    whence -p "$name" 2>/dev/null || true
  fi
}

lazy_is_our_function() {
  local name="$1"
  local body=""

  if [ -n "${ZSH_VERSION:-}" ]; then
    body="${functions[$name]}"
  else
    body="$(declare -f "$name" 2>/dev/null || true)"
  fi

  case "$body" in
    *lazy_*) return 0 ;;
    *) return 1 ;;
  esac
}

lazy_test_module_start() {
  LAZY_TEST_N=0
  LAZY_TEST_FAILS=0
  printf '\n%s\n' "$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
}

lazy_test_line() {
  local name="$1"
  local state="$2"
  local detail="${3:-}"
  LAZY_TEST_N=$((LAZY_TEST_N + 1))

  case "$state" in
    ok)
      printf '%s-%s -> %sok%s\n' "$LAZY_TEST_N" "$name" "$LAZY_TEST_GREEN" "$LAZY_TEST_RESET"
      ;;
    skip)
      printf '%s-%s -> %sskip%s (%s)\n' "$LAZY_TEST_N" "$name" "$LAZY_TEST_YELLOW" "$LAZY_TEST_RESET" "$detail"
      ;;
    *)
      LAZY_TEST_FAILS=$((LAZY_TEST_FAILS + 1))
      LAZY_TEST_TOTAL_FAILS=$((LAZY_TEST_TOTAL_FAILS + 1))
      printf '%s-%s -> %snot ok%s (%s)\n' "$LAZY_TEST_N" "$name" "$LAZY_TEST_RED" "$LAZY_TEST_RESET" "$detail"
      ;;
  esac
}

# Inspect a public command in the *current* shell.
lazy_test_cmd() {
  local name="$1"
  local kind binpath

  kind="$(lazy_cmd_kind "$name")"
  binpath="$(lazy_cmd_path "$name")"

  case "$kind" in
    'alias')
      lazy_test_line "$name" fail "alias conflict"
      ;;
    'function')
      if ! lazy_is_our_function "$name"; then
        lazy_test_line "$name" fail "unknown conflict"
        return
      fi
      if [ -n "$binpath" ]; then
        lazy_test_line "$name" fail "unknown conflict"
        return
      fi
      lazy_test_line "$name" ok
      ;;
    none)
      lazy_test_line "$name" fail "missing"
      ;;
    *)
      lazy_test_line "$name" fail "unknown conflict"
      ;;
  esac
}

lazy_test_public() {
  local module="$1"
  local names=""

  eval "names=\"\${LAZY_PUBLIC_${module}:-}\""

  if [ -z "$names" ]; then
    lazy_test_line "$module" fail "no public commands registered"
    return
  fi

  lazy_each_word lazy_test_cmd "$names"
}

lazy_test_run_module() {
  local module="$1"
  local full="${2:-}"
  local file="${LAZY_ROOT}/modules/${module}/${module}.test.sh"

  lazy_test_module_start "$module"
  lazy_test_public "$module"

  if [ "$full" = "full" ] && [ -f "$file" ]; then
    local b_rc=0
    LAZY_TEST_N="$LAZY_TEST_N" LAZY_ROOT="$LAZY_ROOT" \
      LAZY_CONFIG="${LAZY_CONFIG:-}" LAZY_MODULES="${LAZY_MODULES:-}" \
      bash --noprofile --norc "${LAZY_ROOT}/tests/run-behavior.sh" "$module" || b_rc=$?
    LAZY_TEST_TOTAL_FAILS=$((LAZY_TEST_TOTAL_FAILS + b_rc))
  fi
}

lazy_test_run_all() {
  local full="${1:-}"
  local module
  local pub
  local ran=0

  lazy_test_init_colors
  LAZY_TEST_TOTAL_FAILS=0

  for module in git docker k8s aws node composer; do
    eval "pub=\"\${LAZY_PUBLIC_${module}:-}\""
    if [ -n "${pub:-}" ]; then
      lazy_test_run_module "$module" "$full"
      ran=$((ran + 1))
    fi
  done

  for dir in "${LAZY_ROOT}/modules"/*/; do
    [ -d "$dir" ] || continue
    module="$(basename "$dir")"
    case "$module" in
      git|docker|k8s|aws|node|composer) continue ;;
    esac
    eval "pub=\"\${LAZY_PUBLIC_${module}:-}\""
    if [ -n "${pub:-}" ]; then
      lazy_test_run_module "$module" "$full"
      ran=$((ran + 1))
    fi
  done

  if [ "$ran" -eq 0 ]; then
    printf 'lazy: nothing loaded\n' >&2
    return 1
  fi

  printf '\n'
  if [ "$LAZY_TEST_TOTAL_FAILS" -eq 0 ]; then
    printf '%sall good%s\n' "$LAZY_TEST_GREEN" "$LAZY_TEST_RESET"
    return 0
  fi

  printf '%s%s conflict(s)%s — installer can strip aliases if you want.\n' "$LAZY_TEST_RED" "$LAZY_TEST_TOTAL_FAILS" "$LAZY_TEST_RESET"
  return 1
}

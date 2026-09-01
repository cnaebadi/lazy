#!/usr/bin/env bash
# lib/core.sh — shared helpers for every module.
# Keep this tiny. If it grows, split it.

# Print to stderr without killing the vibe.
lazy_error() {
  printf 'lazy: %s\n' "$*" >&2
}

# True when a command exists on PATH.
lazy_has() {
  command -v "$1" >/dev/null 2>&1
}

# First non-empty argument wins; otherwise fallback.
# usage: lazy_default "$1" "origin"
lazy_default() {
  if [ -n "${1:-}" ]; then
    printf '%s' "$1"
  else
    printf '%s' "$2"
  fi
}

# True when the value looks like a CLI flag (-v, --force, …).
lazy_is_flag() {
  case "${1:-}" in
    -*) return 0 ;;
    *) return 1 ;;
  esac
}

# True when $1 appears in the remaining args (--profile, --profile=prod, …).
lazy_has_flag() {
  local needle="$1"
  shift
  local arg
  for arg in "$@"; do
    case "$arg" in
      "$needle"|"${needle}="*) return 0 ;;
    esac
  done
  return 1
}

# True for common "yes" strings from config files.
lazy_truthy() {
  case "${1:-}" in
    true|TRUE|yes|YES|on|ON|1) return 0 ;;
    *) return 1 ;;
  esac
}

# Drop a colliding alias so a lazy function with the same name actually runs.
# Safe to call when the alias does not exist (must not trip `set -e`).
# The installer asks before using this. modules do not unalias on load.
lazy_unalias() {
  unalias "$1" 2>/dev/null || true
}

# Call $1 for each whitespace-separated word in $2.
# Portable: zsh does not split unquoted vars unless SH_WORD_SPLIT is on.
lazy_each_word() {
  local fn="$1"
  local rest="$2"
  local word

  while [ -n "$rest" ]; do
    word="${rest%% *}"
    if [ "$word" = "$rest" ]; then
      rest=""
    else
      rest="${rest#"$word"}"
      rest="${rest# }"
    fi
    [ -n "$word" ] || continue
    "$fn" "$word"
  done
}

# Unalias every registered public command. Used when LAZY_UNALIAS=true.
lazy_unalias_all() {
  local module names
  for module in git docker k8s aws laravel postgres redis os node composer; do
    eval "names=\"\${LAZY_PUBLIC_${module}:-}\""
    [ -n "$names" ] || continue
    lazy_each_word lazy_unalias "$names"
  done
}

# Remember public command names for tests + installer.
# usage: lazy_register git gs ga gc
lazy_register() {
  local module="$1"
  shift

  eval "LAZY_PUBLIC_${module}=\"$*\""

  case " ${LAZY_MODULES_LOADED:-} " in
    *" ${module} "*) ;;
    *) LAZY_MODULES_LOADED="${LAZY_MODULES_LOADED:-}${LAZY_MODULES_LOADED:+ }${module}" ;;
  esac
}

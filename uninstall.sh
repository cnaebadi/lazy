#!/usr/bin/env bash
# uninstall.sh — remove lazy from your shell. finally working for it.
#
#   ./uninstall.sh
#   ./uninstall.sh -y
#
# env: LAZY_RC  LAZY_CONFIG  LAZY_PREFIX  LAZY_YES

# ── tiny ui (same vibe as install) ───────────────────

lazy_uninstall_colors() {
  if [ -t 1 ]; then
    C_BOLD="$(printf '\033[1m')"
    C_DIM="$(printf '\033[2m')"
    C_GREEN="$(printf '\033[32m')"
    C_YELLOW="$(printf '\033[33m')"
    C_RESET="$(printf '\033[0m')"
  else
    C_BOLD="" C_DIM="" C_GREEN="" C_YELLOW="" C_RESET=""
  fi
}

lazy_uninstall_banner() {
  local _dir=""
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  if [ -n "$_dir" ] && [ -f "${_dir}/lib/banner.sh" ]; then
    # shellcheck source=/dev/null
    . "${_dir}/lib/banner.sh"
    lazy_print_banner "bye"
    return
  fi
  printf '\n'
  printf '  %slazy uninstall%s  %s·  bye%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
  printf '  %s─────────────────────────%s\n' "$C_DIM" "$C_RESET"
}

lazy_uninstall_row() {
  printf '  %s%-10s%s %s\n' "$C_DIM" "$1" "$C_RESET" "$2"
}

lazy_uninstall_ok() {
  printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

lazy_uninstall_tty() {
  if [ -c /dev/tty ]; then printf '%s' /dev/tty; else printf '%s' /dev/stdin; fi
}

lazy_uninstall_ask() {
  local prompt="$1" default="$2" reply=""
  if [ "${LAZY_YES:-0}" = "1" ]; then printf '%s\n' "$default"; return; fi
  printf '            %s' "$prompt" >&2
  if [ -n "$default" ]; then printf '%s[%s]%s ' "$C_DIM" "$default" "$C_RESET" >&2; fi
  read -r reply < "$(lazy_uninstall_tty)" || true
  [ -z "$reply" ] && reply="$default"
  printf '%s\n' "$reply"
}

lazy_uninstall_yes() {
  case "$1" in y|Y|yes|YES|true|TRUE|1|'') return 0 ;; *) return 1 ;; esac
}

lazy_uninstall_detect_shell() {
  local name
  name="$(basename "${SHELL:-zsh}")"
  case "$name" in zsh|bash) printf '%s\n' "$name" ;; *) printf 'zsh\n' ;; esac
}

lazy_uninstall_rc_for() {
  case "$1" in
    zsh) printf '%s\n' "${HOME}/.zshrc" ;;
    bash)
      if [ -f "${HOME}/.bashrc" ] || [ ! -f "${HOME}/.bash_profile" ]; then
        printf '%s\n' "${HOME}/.bashrc"
      else
        printf '%s\n' "${HOME}/.bash_profile"
      fi
      ;;
  esac
}

lazy_uninstall_guess_prefix() {
  local rc="$1" line path
  [ -f "$rc" ] || return 0
  while IFS= read -r line; do
    case "$line" in
      *lazy.sh*)
        path="$(printf '%s' "$line" | sed -n 's/.*"\([^"]*lazy\.sh\)".*/\1/p')"
        if [ -z "$path" ]; then
          path="$(printf '%s' "$line" | sed -n "s/.*'\\([^']*lazy\\.sh\\)'.*/\\1/p")"
        fi
        if [ -n "$path" ] && [ -f "$path" ]; then
          dirname "$path"
          return 0
        fi
        ;;
    esac
  done <<EOF
$(awk '/# >>> lazy >>>/,/# <<< lazy <<</' "$rc" 2>/dev/null)
EOF
}

lazy_uninstall_strip_rc() {
  local rc="$1"
  local tmp
  [ -f "$rc" ] || return 0
  tmp="$(mktemp "${TMPDIR:-/tmp}/lazy-un-rc.XXXXXX")"
  awk '
    /# >>> lazy >>>/ { skip=1; next }
    /# <<< lazy <<</ { skip=0; next }
    skip != 1 { print }
  ' "$rc" > "$tmp"
  mv "$tmp" "$rc"
}

lazy_uninstall_rc_has_block() {
  local rc="$1"
  [ -f "$rc" ] || return 1
  grep -q '# >>> lazy >>>' "$rc" 2>/dev/null
}

lazy_uninstall_usage() {
  cat <<'EOF'
lazy uninstall

  ./uninstall.sh          questions, then remove
  ./uninstall.sh -y       defaults, no questions

env: LAZY_RC  LAZY_CONFIG  LAZY_PREFIX  LAZY_YES
EOF
}

lazy_uninstall_main() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help) lazy_uninstall_usage; exit 0 ;;
      -y|--yes) LAZY_YES=1 ;;
    esac
  done

  lazy_uninstall_colors
  lazy_uninstall_banner

  local shell_name rc_file conf_path prefix remove_conf remove_prefix
  shell_name="$(lazy_uninstall_detect_shell)"
  rc_file="${LAZY_RC:-$(lazy_uninstall_rc_for "$shell_name")}"
  conf_path="${LAZY_CONFIG:-${HOME}/.config/lazy/lazy.conf}"
  prefix="${LAZY_PREFIX:-$(lazy_uninstall_guess_prefix "$rc_file")}"
  [ -n "$prefix" ] || prefix="${HOME}/.lazy"

  lazy_uninstall_row "rc" "$rc_file"
  lazy_uninstall_row "config" "$conf_path"
  lazy_uninstall_row "prefix" "$prefix"

  remove_conf="$(lazy_uninstall_ask "delete config? " "${LAZY_UNINSTALL_RM_CONFIG:-N}")"
  remove_prefix="$(lazy_uninstall_ask "delete prefix dir? " "${LAZY_UNINSTALL_RM_PREFIX:-N}")"

  if lazy_uninstall_rc_has_block "$rc_file"; then
    lazy_uninstall_strip_rc "$rc_file"
    lazy_uninstall_ok "rc block removed"
  else
    lazy_uninstall_ok "rc block not found (already clean)"
  fi

  if lazy_uninstall_yes "$remove_conf" && [ -f "$conf_path" ]; then
    rm -f "$conf_path"
    lazy_uninstall_ok "config deleted"
  else
    lazy_uninstall_ok "config kept"
  fi

  if lazy_uninstall_yes "$remove_prefix" && [ -d "$prefix" ]; then
    # never delete the directory we're running from
    local here=""
    if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
      here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
    if [ -n "$here" ] && [ "$here" = "$prefix" ]; then
      lazy_uninstall_ok "prefix kept (you are inside it)"
    else
      rm -rf "$prefix"
      lazy_uninstall_ok "prefix deleted"
    fi
  else
    lazy_uninstall_ok "prefix kept"
  fi

  printf '\n  %sdone.%s lazy is gone. probably.%s\n\n' "$C_BOLD" "$C_RESET" "$C_RESET"
}

lazy_uninstall_main "$@"

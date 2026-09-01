#!/usr/bin/env bash
# install.sh — one command. a few questions. then you're lazy.
#
#   ./install.sh
#   ./install.sh -y              # accept defaults (no prompts)
#   curl -fsSL <raw>/install.sh | bash
#
# env overrides:
#   LAZY_PREFIX   install dir     (repo dir, or ~/.lazy)
#   LAZY_CONFIG   config path     (~/.config/lazy/lazy.conf)
#   LAZY_RC       rc file         (~/.zshrc or ~/.bashrc)
#   LAZY_REPO     git url to clone when this file is piped
#   LAZY_YES=1    same as -y

LAZY_READY_MODULES="git,docker,k8s,aws,node,composer"
LAZY_REPO="${LAZY_REPO:-https://github.com/cnaebadi/lazy.git}"

# ── tiny ui ──────────────────────────────────────────

lazy_install_colors() {
  if [ -t 1 ]; then
    C_BOLD="$(printf '\033[1m')"
    C_DIM="$(printf '\033[2m')"
    C_GREEN="$(printf '\033[32m')"
    C_YELLOW="$(printf '\033[33m')"
    C_CYAN="$(printf '\033[36m')"
    C_RESET="$(printf '\033[0m')"
  else
    C_BOLD="" C_DIM="" C_GREEN="" C_YELLOW="" C_CYAN="" C_RESET=""
  fi
}

lazy_install_banner() {
  local _dir=""
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  if [ -n "$_dir" ] && [ -f "${_dir}/lib/banner.sh" ]; then
    # shellcheck source=/dev/null
    . "${_dir}/lib/banner.sh"
    lazy_print_banner "too lazy to type"
    return
  fi
  printf '\n'
  printf '  %slazy%s  %s·  too lazy to type%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
  printf '  %s─────────────────────────%s\n' "$C_DIM" "$C_RESET"
}

lazy_install_row() {
  printf '  %s%-10s%s %s\n' "$C_DIM" "$1" "$C_RESET" "$2"
}

lazy_install_ok() {
  printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

# ── io ───────────────────────────────────────────────

lazy_install_tty() {
  if [ -c /dev/tty ]; then
    printf '%s' /dev/tty
  else
    printf '%s' /dev/stdin
  fi
}

lazy_install_ask() {
  # $1 prompt  $2 default
  local prompt="$1"
  local default="$2"
  local reply=""

  if [ "${LAZY_YES:-0}" = "1" ]; then
    printf '%s\n' "$default"
    return
  fi

  printf '            %s' "$prompt" >&2
  if [ -n "$default" ]; then
    printf '%s[%s]%s ' "$C_DIM" "$default" "$C_RESET" >&2
  fi
  read -r reply < "$(lazy_install_tty)" || true
  if [ -z "$reply" ]; then
    reply="$default"
  fi
  printf '%s\n' "$reply"
}

lazy_install_yes() {
  case "$1" in
    y|Y|yes|YES|true|TRUE|1|'') return 0 ;;
    *) return 1 ;;
  esac
}

# ── detect ───────────────────────────────────────────

lazy_install_src() {
  local dir=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi

  # Piped (curl | bash): no real source file. clone, then re-exec.
  if [ -z "$dir" ] || [ ! -f "${dir}/lazy.sh" ]; then
    dir="${HOME}/.lazy"
    if [ ! -f "${dir}/lazy.sh" ]; then
      printf '  cloning %s\n' "$LAZY_REPO" >&2
      git clone --depth 1 "$LAZY_REPO" "$dir" || {
        printf 'lazy: clone failed. set LAZY_REPO or run ./install.sh from a checkout.\n' >&2
        exit 1
      }
    fi
    exec bash "${dir}/install.sh" "$@"
  fi

  printf '%s\n' "$dir"
}

lazy_install_detect_shell() {
  local name
  name="$(basename "${SHELL:-zsh}")"
  case "$name" in
    zsh|bash) printf '%s\n' "$name" ;;
    *) printf 'zsh\n' ;;
  esac
}

lazy_install_rc_for() {
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

lazy_install_normalize_modules() {
  local raw="$1"
  local out=""
  local item
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr ',' ' ')"

  case "$raw" in
    all|'') printf '%s\n' "$LAZY_READY_MODULES"; return ;;
  esac

  for item in $raw; do
    case "$item" in
      git|docker|k8s|aws|laravel|postgres|redis|os|node|composer) ;;
      kube|kubernetes) item=k8s ;;
      *) continue ;;
    esac
    case ",${out}," in
      *",${item},"*) ;;
      *) out="${out}${out:+,}${item}" ;;
    esac
  done

  if [ -z "$out" ]; then
    out="$LAZY_READY_MODULES"
  fi
  printf '%s\n' "$out"
}

# ── aliases ──────────────────────────────────────────

lazy_install_scan_aliases() {
  # Print "name<TAB>value" for aliases that collide with selected lazy commands.
  local shell="$1"
  local commands="$2"
  local dump line name value

  dump="$("$shell" -i -c 'alias -L 2>/dev/null || alias' </dev/null 2>/dev/null)" || true
  [ -n "$dump" ] || return 0

  printf '%s\n' "$dump" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    line="${line#alias }"
    name="${line%%=*}"
    value="${line#*=}"
    name="$(printf '%s' "$name" | tr -d " '\"")"
    [ -n "$name" ] || continue
    case " ${commands} " in
      *" ${name} "*) printf '%s\t%s\n' "$name" "$value" ;;
    esac
  done
}

lazy_install_command_list() {
  # Space-separated public names for a csv module list. uses already-sourced lazy.
  local csv="$1"
  local module names all=""
  local IFS=','

  for module in $csv; do
    eval "names=\"\${LAZY_PUBLIC_${module}:-}\""
    all="${all}${all:+ }${names}"
  done
  printf '%s\n' "$all"
}

# ── write files ──────────────────────────────────────

lazy_install_sync() {
  local src="$1"
  local prefix="$2"
  local item

  if [ "$src" = "$prefix" ]; then
    return 0
  fi

  mkdir -p "$prefix"
  for item in lazy.sh install.sh uninstall.sh lib modules config tests docs assets README.md; do
    if [ -e "${src}/${item}" ]; then
      rm -rf "${prefix:?}/${item}"
      cp -R "${src}/${item}" "${prefix}/${item}"
    fi
  done
}

lazy_install_write_config() {
  local path="$1"
  local modules="$2"
  local remote="$3"
  local unalias="$4"

  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
# lazy — generated by install.sh
LAZY_MODULES=${modules}
LAZY_UNALIAS=${unalias}
GIT_REMOTE=${remote}
EOF
}

lazy_install_rc_block() {
  local prefix="$1"
  local modules="$2"
  local unalias="$3"
  local remote="$4"
  local with_conf="$5"

  if lazy_install_yes "$with_conf"; then
    cat <<EOF
# >>> lazy >>>
[ -f "${prefix}/lazy.sh" ] && . "${prefix}/lazy.sh"
# <<< lazy <<<
EOF
  else
    cat <<EOF
# >>> lazy >>>
export LAZY_MODULES="${modules}"
export LAZY_UNALIAS="${unalias}"
export GIT_REMOTE="${remote}"
[ -f "${prefix}/lazy.sh" ] && . "${prefix}/lazy.sh"
# <<< lazy <<<
EOF
  fi
}

lazy_install_hook_rc() {
  local rc="$1"
  local prefix="$2"
  local modules="$3"
  local unalias="$4"
  local remote="$5"
  local with_conf="$6"
  local tmp block

  tmp="$(mktemp "${TMPDIR:-/tmp}/lazy-rc.XXXXXX")"
  if [ -f "$rc" ]; then
    awk '
      /# >>> lazy >>>/ { skip=1; next }
      /# <<< lazy <<</ { skip=0; next }
      skip != 1 { print }
    ' "$rc" > "$tmp"
  else
    : > "$tmp"
  fi

  block="$(lazy_install_rc_block "$prefix" "$modules" "$unalias" "$remote" "$with_conf")"
  printf '\n%s\n' "$block" >> "$tmp"
  mv "$tmp" "$rc"
}

# ── tests after install ──────────────────────────────

lazy_install_run_tests() {
  local shell="$1"
  local prefix="$2"
  local conf="$3"

  printf '\n  %stesting%s\n' "$C_BOLD" "$C_RESET"

  if [ "${LAZY_YES:-0}" = "1" ]; then
    bash --noprofile --norc -c "
      export LAZY_TEST_FORCE_COLOR=1
      export LAZY_CONFIG='${conf}'
      . '${prefix}/lazy.sh'
      . '${prefix}/lib/test.sh'
      lazy_test_run_all || true
    "
    return
  fi

  "$shell" -i -c "
    export LAZY_TEST_FORCE_COLOR=1
    export LAZY_CONFIG='${conf}'
    if [ -z \"\${LAZY_ROOT:-}\" ]; then
      . '${prefix}/lazy.sh'
    fi
    . '${prefix}/lib/test.sh'
    lazy_test_run_all || true
  " </dev/null
}

# ── main ─────────────────────────────────────────────

lazy_install_usage() {
  cat <<'EOF'
lazy installer

  ./install.sh          questions, then install
  ./install.sh -y       defaults, no questions
  ./install.sh -h       this

env: LAZY_PREFIX  LAZY_CONFIG  LAZY_RC  LAZY_REPO  LAZY_YES
EOF
}

lazy_install_main() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h|--help) lazy_install_usage; exit 0 ;;
      -y|--yes) LAZY_YES=1 ;;
    esac
  done

  lazy_install_colors
  lazy_install_banner

  local src shell_name prefix rc_file modules write_conf remote strip_alias hook_rc
  local commands conflicts nconf conf_path unalias_val

  src="$(lazy_install_src "$@")"
  prefix="${LAZY_PREFIX:-$src}"
  shell_name="$(lazy_install_detect_shell)"
  rc_file="${LAZY_RC:-$(lazy_install_rc_for "$shell_name")}"
  conf_path="${LAZY_CONFIG:-${HOME}/.config/lazy/lazy.conf}"

  lazy_install_row "path" "$prefix"
  lazy_install_row "shell" "$shell_name"
  if ! lazy_install_yes "$(lazy_install_ask "ok? " "Y")"; then
    shell_name="$(lazy_install_ask "bash or zsh? " "zsh")"
    case "$shell_name" in bash|zsh) ;; *) shell_name=zsh ;; esac
    rc_file="${LAZY_RC:-$(lazy_install_rc_for "$shell_name")}"
    lazy_install_row "shell" "$shell_name"
  fi

  lazy_install_row "modules" "$LAZY_READY_MODULES"
  modules="$(lazy_install_normalize_modules "$(lazy_install_ask "list? " "$LAZY_READY_MODULES")")"
  lazy_install_row "modules" "$modules"

  lazy_install_row "config" "$conf_path"
  write_conf="$(lazy_install_ask "write it? " "Y")"

  remote="origin"
  case ",${modules}," in
    *,git,*)
      lazy_install_row "remote" "origin"
      remote="$(lazy_install_ask "git push default? " "origin")"
      [ -n "$remote" ] || remote=origin
      lazy_install_row "remote" "$remote"
      ;;
  esac

  LAZY_CONFIG="${TMPDIR:-/tmp}/lazy-install-noconf"
  LAZY_MODULES="$modules"
  # shellcheck source=/dev/null
  . "${src}/lazy.sh"
  commands="$(lazy_install_command_list "$modules")"

  conflicts=""
  nconf=0
  if [ "${LAZY_YES:-0}" != "1" ]; then
    printf '  %s%-10s%s %s\n' "$C_DIM" "aliases" "$C_RESET" "${C_DIM}scanning ${shell_name}...${C_RESET}"
    conflicts="$(lazy_install_scan_aliases "$shell_name" "$commands")"
    if [ -n "$conflicts" ]; then
      nconf="$(printf '%s\n' "$conflicts" | grep -c . || true)"
    fi
  fi

  strip_alias="Y"
  if [ "$nconf" -gt 0 ]; then
    lazy_install_row "aliases" "${C_YELLOW}${nconf} conflict(s)${C_RESET}"
    printf '%s\n' "$conflicts" | while IFS="$(printf '\t')" read -r name value; do
      printf '            %s%-8s%s %s\n' "$C_CYAN" "$name" "$C_RESET" "$C_DIM${value}${C_RESET}"
    done
    strip_alias="$(lazy_install_ask "strip them on start? " "Y")"
  else
    lazy_install_row "aliases" "none. nice."
  fi

  lazy_install_row "rc" "$rc_file"
  hook_rc="$(lazy_install_ask "hook it? " "Y")"

  printf '\n'
  lazy_install_sync "$src" "$prefix"
  lazy_install_ok "files  ${prefix}"

  unalias_val=false
  if lazy_install_yes "$strip_alias"; then
    unalias_val=true
  fi

  if lazy_install_yes "$write_conf"; then
    lazy_install_write_config "$conf_path" "$modules" "$remote" "$unalias_val"
    lazy_install_ok "config ${conf_path}"
  else
    lazy_install_ok "config skipped (defaults)"
  fi

  if lazy_install_yes "$hook_rc"; then
    lazy_install_hook_rc "$rc_file" "$prefix" "$modules" "$unalias_val" "$remote" "$write_conf"
    lazy_install_ok "rc     ${rc_file}"
  else
    lazy_install_ok "rc skipped — add this yourself:"
    printf '\n%s\n\n' "$(lazy_install_rc_block "$prefix" "$modules" "$unalias_val" "$remote" "$write_conf")"
  fi

  lazy_install_run_tests "$shell_name" "$prefix" "$conf_path"

  printf '\n  %sdone.%s  new tab, or:  %s. %s%s\n\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$rc_file" "$C_RESET"
}

lazy_install_main "$@"

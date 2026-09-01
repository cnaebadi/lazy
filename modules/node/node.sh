#!/usr/bin/env bash
# modules/node/node.sh — npm / yarn / pnpm / bun shortcuts
# prefix: n
# public: ni nadd nr nrd nrb nt nout
#
# usage:
#   ni                         install deps (pm from NODE_PACKAGE_MANAGER)
#   nadd lodash                add package
#   nr build                   run script
#   nrd / nrb / nt             run dev / build / test
#   nout                       outdated packages
#
# NODE_PACKAGE_MANAGER=npm|yarn|pnpm|bun  (default: npm, auto-detect if unset)

# ── internals ────────────────────────────────────────

lazy_node_pm() {
  local pm="${NODE_PACKAGE_MANAGER:-}"

  if [ -n "$pm" ]; then
    printf '%s' "$pm"
    return
  fi

  for pm in pnpm yarn bun npm; do
    if lazy_has "$pm"; then
      printf '%s' "$pm"
      return
    fi
  done

  printf '%s' "npm"
}

lazy_node_require() {
  local pm
  pm="$(lazy_node_pm)"
  if ! lazy_has "$pm"; then
    lazy_error "${pm} is not installed"
    return 127
  fi
  printf '%s' "$pm"
}

lazy_node_run() {
  local pm
  pm="$(lazy_node_require)" || return $?
  command "$pm" "$@"
}

lazy_node_install() {
  local pm
  pm="$(lazy_node_require)" || return $?

  case "$pm" in
    yarn) yarn install "$@" ;;
    pnpm) pnpm install "$@" ;;
    bun) bun install "$@" ;;
    *) npm install "$@" ;;
  esac
}

lazy_node_add() {
  if [ $# -eq 0 ]; then
    lazy_error "nadd <package>"
    return 2
  fi

  local pm
  pm="$(lazy_node_require)" || return $?

  case "$pm" in
    yarn) yarn add "$@" ;;
    pnpm) pnpm add "$@" ;;
    bun) bun add "$@" ;;
    *) npm install "$@" ;;
  esac
}

lazy_node_script() {
  local script="$1"
  shift

  if [ -z "$script" ]; then
    lazy_error "nr <script>"
    return 2
  fi

  local pm
  pm="$(lazy_node_require)" || return $?

  case "$pm" in
    yarn) yarn "$script" "$@" ;;
    pnpm) pnpm run "$script" "$@" ;;
    bun) bun run "$script" "$@" ;;
    *) npm run "$script" "$@" ;;
  esac
}

lazy_node_outdated() {
  local pm
  pm="$(lazy_node_require)" || return $?

  case "$pm" in
    yarn) yarn outdated "$@" ;;
    pnpm) pnpm outdated "$@" ;;
    bun) bun outdated "$@" ;;
    *) npm outdated "$@" ;;
  esac
}

# ── public API ───────────────────────────────────────

lazy_register node ni nadd nr nrd nrb nt nout

function ni() {
  lazy_node_install "$@"
}

function nadd() {
  lazy_node_add "$@"
}

function nr() {
  lazy_node_script "$@"
}

function nrd() {
  lazy_node_script dev "$@"
}

function nrb() {
  lazy_node_script build "$@"
}

function nt() {
  lazy_node_script test "$@"
}

function nout() {
  lazy_node_outdated "$@"
}

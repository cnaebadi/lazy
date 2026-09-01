#!/usr/bin/env bash
# modules/docker/docker.sh — docker / compose shortcuts
# prefix: d
# public: dps dcu dcd dcr dlogs denter
#
# usage:
#   dps                        docker ps
#   dps -a                     docker ps -a
#   dcu                        compose -f $DOCKER_COMPOSE_FILE up -d
#   dcu prod.yml               override compose file
#   dcu --build                flags after optional file
#   dcd / dcr / dlogs          down / restart / logs -f
#   denter                     exec -it into the only running container
#   denter web                 exec -it web sh
#   denter web bash            pick a shell

# ── internals ────────────────────────────────────────

lazy_docker_require() {
  if ! lazy_has docker; then
    lazy_error "docker is not installed"
    return 127
  fi
}

# Prefer `docker compose` (v2 plugin), fall back to the old binary.
lazy_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    command docker compose "$@"
    return $?
  fi

  if lazy_has docker-compose; then
    docker-compose "$@"
    return $?
  fi

  lazy_error "docker compose is not installed"
  return 127
}

lazy_docker_compose_with_file() {
  local file="$1"
  shift

  if [ -n "${DOCKER_COMPOSE_PROJECT:-}" ]; then
    lazy_docker_compose -f "$file" -p "$DOCKER_COMPOSE_PROJECT" "$@"
    return $?
  fi

  lazy_docker_compose -f "$file" "$@"
}

lazy_docker_ps() {
  lazy_docker_require || return $?
  command docker ps "$@"
}

lazy_docker_up() {
  lazy_docker_require || return $?
  local file="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    case "$1" in
      *.yml|*.yaml) file="$1"; shift ;;
    esac
  fi
  lazy_docker_compose_with_file "$file" up -d "$@"
}

lazy_docker_down() {
  lazy_docker_require || return $?
  local file="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    case "$1" in
      *.yml|*.yaml) file="$1"; shift ;;
    esac
  fi
  lazy_docker_compose_with_file "$file" down "$@"
}

lazy_docker_restart() {
  lazy_docker_require || return $?
  local file="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    case "$1" in
      *.yml|*.yaml) file="$1"; shift ;;
    esac
  fi
  lazy_docker_compose_with_file "$file" restart "$@"
}

lazy_docker_logs() {
  lazy_docker_require || return $?
  local file="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    case "$1" in
      *.yml|*.yaml) file="$1"; shift ;;
    esac
  fi
  lazy_docker_compose_with_file "$file" logs -f "$@"
}

# No name → the only running container. Several running → list them and quit.
lazy_docker_enter() {
  lazy_docker_require || return $?

  local name shell
  name="${1:-}"

  if [ -z "$name" ]; then
    local names
    names="$(command docker ps --format '{{.Names}}' 2>/dev/null)" || return $?

    if [ -z "$names" ]; then
      lazy_error "no running containers"
      return 1
    fi

    if [ "$(printf '%s\n' "$names" | wc -l | tr -d ' ')" != "1" ]; then
      lazy_error "pick one: denter <name>"
      printf '%s\n' "$names" >&2
      return 2
    fi

    name="$names"
  else
    shift
  fi

  shell="${1:-sh}"
  if [ $# -gt 0 ]; then
    shift
  fi

  command docker exec -it "$name" "$shell" "$@"
}

# ── public API ───────────────────────────────────────

lazy_register docker dps dcu dcd dcr dlogs denter

function dps() {
  lazy_docker_ps "$@"
}

function dcu() {
  lazy_docker_up "$@"
}

function dcd() {
  lazy_docker_down "$@"
}

function dcr() {
  lazy_docker_restart "$@"
}

function dlogs() {
  lazy_docker_logs "$@"
}

function denter() {
  lazy_docker_enter "$@"
}

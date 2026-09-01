#!/usr/bin/env bash
# lib/config.sh — load user config with sane defaults.
#
# Search order:
#   1. $LAZY_CONFIG (explicit override)
#   2. ~/.config/lazy/lazy.conf
#   3. built-in defaults below

lazy_set_defaults() {
  : "${GIT_REMOTE:=origin}"
  : "${GIT_PULL_REBASE:=true}"

  : "${DOCKER_COMPOSE_FILE:=docker-compose.yml}"

  : "${K8S_NAMESPACE:=default}"

  : "${PG_HOST:=localhost}"
  : "${PG_PORT:=5432}"
  : "${PG_USER:=postgres}"

  : "${REDIS_HOST:=localhost}"
  : "${REDIS_PORT:=6379}"

  : "${AWS_PROFILE_DEFAULT:=default}"
  : "${AWS_REGION_DEFAULT:=us-east-1}"

  : "${NODE_PACKAGE_MANAGER:=}"
  : "${LAZY_UNALIAS:=false}"
}

lazy_load_config() {
  lazy_set_defaults

  local conf="${LAZY_CONFIG:-${HOME}/.config/lazy/lazy.conf}"

  if [ -f "$conf" ]; then
    # shellcheck source=/dev/null
    . "$conf"
  fi
}

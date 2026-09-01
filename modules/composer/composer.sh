#!/usr/bin/env bash
# modules/composer/composer.sh — composer shortcuts
# prefix: c
# public: cins cup creq cdu crun
#
# usage:
#   cins                       composer install
#   cup                        composer update
#   creq laravel/sanctum       composer require
#   cdu                        dump-autoload
#   crun test                  composer run-script test

# ── internals ────────────────────────────────────────

lazy_composer_require() {
  if ! lazy_has composer; then
    lazy_error "composer is not installed"
    return 127
  fi
}

lazy_composer() {
  lazy_composer_require || return $?
  command composer "$@"
}

lazy_composer_install() {
  lazy_composer install "$@"
}

lazy_composer_update() {
  lazy_composer update "$@"
}

lazy_composer_require_pkg() {
  if [ $# -eq 0 ]; then
    lazy_error "creq <package>"
    return 2
  fi
  lazy_composer require "$@"
}

lazy_composer_dump() {
  lazy_composer dump-autoload "$@"
}

lazy_composer_run() {
  if [ $# -eq 0 ]; then
    lazy_error "crun <script>"
    return 2
  fi
  lazy_composer run-script "$@"
}

# ── public API ───────────────────────────────────────

lazy_register composer cins cup creq cdu crun

function cins() {
  lazy_composer_install "$@"
}

function cup() {
  lazy_composer_update "$@"
}

function creq() {
  lazy_composer_require_pkg "$@"
}

function cdu() {
  lazy_composer_dump "$@"
}

function crun() {
  lazy_composer_run "$@"
}

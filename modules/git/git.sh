#!/usr/bin/env bash
# modules/git/git.sh — git shortcuts
# prefix: g
# public: gs ga gc gca gps gpl glog gundo
#
# usage:
#   gs                         git status
#   ga                         git add .
#   ga file                    git add file
#   gc                         git commit          (opens editor)
#   gc "msg"                   git commit -m msg
#   gca                        git commit --amend
#   gca "msg"                  git commit --amend -m msg
#   gps                        git push <GIT_REMOTE> <current>
#   gps hamgit                 git push hamgit <current>
#   gps hamgit main            git push hamgit main
#   gps --force                flags after optional remote/branch
#   gpl                        git pull [--rebase] <GIT_REMOTE> <current>
#   glog                       pretty log
#   gundo                      uncommit last (soft reset, keeps files)
#   gundo --hard               drop last commit AND its changes

# ── internals ────────────────────────────────────────

lazy_git_require() {
  if ! lazy_has git; then
    lazy_error "git is not installed"
    return 127
  fi

  if ! command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    lazy_error "not a git repository"
    return 1
  fi
}

lazy_git_current_branch() {
  local branch
  branch="$(git branch --show-current 2>/dev/null)"

  if [ -z "$branch" ]; then
    lazy_error "not on a branch (detached HEAD?)"
    return 1
  fi

  printf '%s' "$branch"
}

# True when config wants rebase AND the user did not already pass a rebase flag.
lazy_git_needs_rebase_flag() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --rebase|--no-rebase) return 1 ;;
    esac
  done
  lazy_truthy "${GIT_PULL_REBASE:-true}"
}

# Shared push/pull path so remote+branch parsing lives in one place.
# usage: lazy_git_remote_cmd push|pull [remote] [branch] [flags...]
lazy_git_remote_cmd() {
  local action="$1"
  shift

  local remote="${GIT_REMOTE:-origin}"
  local branch

  branch="$(lazy_git_current_branch)" || return $?

  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    remote="$1"
    shift
  fi

  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    branch="$1"
    shift
  fi

  case "$action" in
    push)
      git push "$remote" "$branch" "$@"
      ;;
    pull)
      if lazy_git_needs_rebase_flag "$@"; then
        git pull --rebase "$remote" "$branch" "$@"
      else
        git pull "$remote" "$branch" "$@"
      fi
      ;;
    *)
      lazy_error "unknown git action: $action"
      return 2
      ;;
  esac
}

lazy_git_status() {
  lazy_git_require || return $?
  git status "$@"
}

lazy_git_add() {
  lazy_git_require || return $?

  if [ $# -eq 0 ]; then
    git add .
    return $?
  fi

  git add "$@"
}

# Bare call opens the editor. A non-flag first arg is the commit message.
lazy_git_commit() {
  lazy_git_require || return $?

  if [ $# -eq 0 ]; then
    git commit
    return $?
  fi

  if lazy_is_flag "$1"; then
    git commit "$@"
    return $?
  fi

  local message="$1"
  shift
  git commit -m "$message" "$@"
}

lazy_git_commit_amend() {
  lazy_git_require || return $?

  if [ $# -eq 0 ]; then
    git commit --amend
    return $?
  fi

  if lazy_is_flag "$1"; then
    git commit --amend "$@"
    return $?
  fi

  local message="$1"
  shift
  git commit --amend -m "$message" "$@"
}

lazy_git_push() {
  lazy_git_require || return $?
  lazy_git_remote_cmd push "$@"
}

lazy_git_pull() {
  lazy_git_require || return $?
  lazy_git_remote_cmd pull "$@"
}

lazy_git_log() {
  lazy_git_require || return $?
  git log \
    --graph \
    --abbrev-commit \
    --decorate \
    --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' \
    "$@"
}

# Default is --soft: last commit disappears, working tree stays.
# Pass reset flags through, e.g. gundo --hard / gundo --mixed.
lazy_git_undo() {
  lazy_git_require || return $?

  if [ $# -gt 0 ] && ! lazy_is_flag "$1"; then
    lazy_error "gundo: pass reset flags only, e.g. gundo --hard"
    return 2
  fi

  if [ $# -eq 0 ]; then
    git reset --soft HEAD~1
    return $?
  fi

  git reset "$@" HEAD~1
}

# ── public API ───────────────────────────────────────
# `function name()` so zsh can define these even when an alias exists.
# we do NOT unalias here — installer asks, tests report leftovers.

lazy_register git gs ga gc gca gps gpl glog gundo

function gs() {
  lazy_git_status "$@"
}

function ga() {
  lazy_git_add "$@"
}

function gc() {
  lazy_git_commit "$@"
}

function gca() {
  lazy_git_commit_amend "$@"
}

function gps() {
  lazy_git_push "$@"
}

function gpl() {
  lazy_git_pull "$@"
}

function glog() {
  lazy_git_log "$@"
}

function gundo() {
  lazy_git_undo "$@"
}

#!/usr/bin/env bash
# modules/git/git.test.sh — full behavior coverage

# shellcheck source=/dev/null
. "${LAZY_ROOT}/tests/helpers.sh"

lazy_test_git_repo() {
  local tmp="$1"
  git init -q "$tmp"
  git -C "$tmp" config user.email "lazy@test"
  git -C "$tmp" config user.name "lazy"
}

lazy_test_git_full() {
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/lazy-git-test.XXXXXX")" || {
    lazy_test_line "git:init" fail "mktemp"
    return
  }

  if ! lazy_has git; then
    rm -rf "$tmp"
    lazy_test_line "git:binary" skip "git not installed"
    return
  fi

  lazy_test_git_repo "$tmp"

  (
    cd "$tmp" || exit 1
    export GIT_REMOTE=origin
    export GIT_PULL_REBASE=true

    # gs
    gs >/dev/null || exit 1

    # ga default + file
    printf 'a\n' > f.txt
    ga || exit 1
    ga f.txt || exit 1

    # gc message + gca
    gc "first" >/dev/null 2>&1 || exit 1
    printf 'c\n' >> f.txt
    ga f.txt || exit 1
    gc "second" >/dev/null 2>&1 || exit 1
    gca "amended" >/dev/null 2>&1 || exit 1

    # glog
    glog -n 1 >/dev/null || exit 1

    # gundo soft keeps changes
    printf 'b\n' >> f.txt
    ga f.txt && gc "third" >/dev/null 2>&1
    gundo >/dev/null 2>&1 || exit 1
    [ "$(git rev-list --count HEAD)" = "2" ] || exit 1
    grep -q 'b' f.txt || exit 1

    # gundo --hard
    gc "tmp" >/dev/null 2>&1
    gundo --hard >/dev/null 2>&1 || exit 1

    # gundo bad arg
    gundo not-a-flag >/dev/null 2>&1 && exit 1

    # gps/gpl remote override (expect push/pull to fail — no remote)
    gps 2>"${tmp}/lazy-gps.err" || true
    grep -q origin "${tmp}/lazy-gps.err" || exit 1
    gps hamgit 2>"${tmp}/lazy-gps-h.err" || true
    grep -qi hamgit "${tmp}/lazy-gps-h.err" || exit 1

    gpl 2>"${tmp}/lazy-gpl.err" || true
    grep -q origin "${tmp}/lazy-gpl.err" || exit 1
  )
  local rc=$?

  rm -rf "$tmp"

  if [ "$rc" -eq 0 ]; then
    lazy_test_line "git:behavior" ok
  else
    lazy_test_line "git:behavior" fail "commands"
  fi

  # outside repo — must not run inside lazy checkout
  local saved="$PWD"
  cd "${TMPDIR:-/tmp}" || return
  lazy_test_assert_fail "git:outside" gs
  cd "$saved" || true
}

lazy_test_git_remote_branch() {
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/lazy-git-rb-test.XXXXXX")" || {
    lazy_test_line "git:remote-branch" fail "mktemp"
    return
  }

  if ! lazy_has git; then
    rm -rf "$tmp"
    lazy_test_line "git:remote-branch" skip "git not installed"
    return
  fi

  lazy_test_git_repo "$tmp"

  (
    cd "$tmp" || exit 1

    command git remote add origin .
    command git remote add hamgit .
    command git checkout -b development >/dev/null 2>&1

    local real_git
    real_git="$(command -v git)"

    lazy_test_mock_reset
    lazy_test_mock_cmd git "
case \"\$1\" in
  remote|branch|rev-parse)
    ${real_git} \"\$@\"
    ;;
  *)
    printf \"%s\n\" \"\$*\" >> \"\$LAZY_TEST_MOCK_DIR/log/git\"
    exit 0
    ;;
esac
"

    export GIT_REMOTE=hamgit
    export GIT_PULL_REBASE=true

    gpl development >/dev/null 2>&1 || exit 1
    lazy_test_assert_contains "git:gpl-branch" "$(lazy_test_mock_last git)" "pull --rebase hamgit development"

    gps hamgit >/dev/null 2>&1 || exit 1
    lazy_test_assert_contains "git:gps-remote" "$(lazy_test_mock_last git)" "push hamgit development"

    gps main >/dev/null 2>&1 || exit 1
    lazy_test_assert_contains "git:gps-branch" "$(lazy_test_mock_last git)" "push hamgit main"

    gpl hamgit main >/dev/null 2>&1 || exit 1
    lazy_test_assert_contains "git:gpl-remote-branch" "$(lazy_test_mock_last git)" "pull --rebase hamgit main"
  )
  local rc=$?

  rm -rf "$tmp"
  [ "$rc" -eq 0 ] || return
}

lazy_test_git_full
lazy_test_git_remote_branch

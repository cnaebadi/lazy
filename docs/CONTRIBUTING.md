# contributing (keep it lazy)

thanks for wanting to help. read this once. then write less.

## maintainer note

i'm lazy. that's the whole point of this repo.

- i will **not** review PRs quickly
- i may forget your PR for weeks
- don't ping me every day
- if it's clean and follows the rules below, it'll land eventually

no hard feelings. just vibes.

---

## naming rules

every short command **must** follow these:

### 1. domain prefix

| prefix | domain    |
|--------|-----------|
| `g`    | git       |
| `d`    | docker    |
| `k`    | k8s       |
| `l`    | laravel   |
| `pg`   | postgres  |
| `rd`   | redis     |
| `a`    | aws       |
| `n`    | node/npm  |
| `c`    | composer  |
| *(none / short verb)* | os / linux / macos |

no exceptions. if it's git, it starts with `g`. always. (`gundo`, not `undo`)

### 2. short verb

use obvious stubs:

`s` status · `a` add · `c` commit · `ps` push/ps · `pl` pull · `l` logs · `r` restart · `u` up · `d` down

combine: prefix + verb → `gs`, `gps`, `dcu`, `dlogs`

### 3. length

- prefer **2–4** chars
- hard max **6** chars
- if you need more, the command is wrong or should be a flag

### 4. arguments override config

```bash
gps              # uses GIT_REMOTE from config (default: origin)
gps hamgit       # override remote once
gps hamgit main  # remote + branch
```

never hardcode values that belong in config.

### 5. functions only

- **no** shell aliases
- **no** one-liner wrappers that hide logic
- one public function = one lazy command
- shared logic goes in `lib/`

### 6. clean & extendable

- one job per function
- name internals clearly (`lazy_git_push`, not `do_it`)
- comment the *why*, not the obvious *what*
- bash **and** zsh must work
- avoid bashisms that break zsh (and vice versa)
- don't shadow common system commands (`ls`, `cd`, `cat`, …)

### 7. aliases are the user's problem — until they say otherwise

do **not** silently `unalias` on load. the installer asks. tests show the leftover mess:

```
GIT
1-gs -> ok
2-ga -> not ok (alias conflict)
3-gc -> not ok (unknown conflict)
```

use `function name() { ... }` so zsh can still *define* the function when an alias exists.

### 8. tests

every public command needs a test in `modules/<domain>/<domain>.test.sh`.

- health: function exists, no alias in the way, no surprise binary
- behavior (full mode): the command actually does the thing, or `skip` if the tool isn't installed

### 9. docs

every public command must be documented in `docs/<domain>.md`.

- add a row to the command table when you add a command
- update the module header comment in `modules/<domain>/<domain>.sh` too
- new module? add `docs/<domain>.md` and link it from `docs/README.md`
- placeholder modules stay marked **not implemented yet** until they ship

if you add a command but skip docs or tests, the PR is incomplete.

---

## module layout

```
modules/<domain>/
  <domain>.sh         # internals + public functions
  <domain>.test.sh    # one check per public command
docs/
  <domain>.md         # command reference for that module
  README.md           # index of all modules
```

shared helpers → `lib/`.

config keys → `config/lazy.conf.example` (and document the default).

---

## PR checklist

- [ ] every command has the module prefix
- [ ] function, not alias
- [ ] works in bash and zsh
- [ ] args can override config
- [ ] tests for every public command
- [ ] docs updated in `docs/<domain>.md`
- [ ] short comment on non-obvious behavior
- [ ] updated example config if you added a key
- [ ] no unrelated refactors

small PRs > big PRs. i'm lazy, remember?

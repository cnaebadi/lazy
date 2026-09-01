# git (`g`)

prefix: **g** · needs: `git`

| command | does |
|---------|------|
| `gs` | `git status` |
| `ga` | `git add .` |
| `ga file` | `git add file` |
| `gc` | `git commit` (opens editor) |
| `gc "msg"` | `git commit -m "msg"` |
| `gca` | `git commit --amend` |
| `gca "msg"` | `git commit --amend -m "msg"` |
| `gps` | `git push <GIT_REMOTE> <current branch>` |
| `gps hamgit` | push current branch to remote `hamgit` |
| `gps main` | push branch `main` to `<GIT_REMOTE>` |
| `gps hamgit main` | push branch `main` to `hamgit` |
| `gps --force` | flags pass through after remote/branch |
| `gpl` | `git pull [--rebase] <GIT_REMOTE> <current branch>` |
| `gpl development` | pull branch `development` from `<GIT_REMOTE>` |
| `gpl hamgit main` | pull branch `main` from `hamgit` |
| `glog` | pretty one-line log |
| `gundo` | soft reset last commit (keeps changes) |
| `gundo --hard` | drop last commit and its changes |

**config:** `GIT_REMOTE` (default `origin`), `GIT_PULL_REBASE` (default `true`).

**push/pull args:** one positional arg = remote if it exists, otherwise branch. two args = remote + branch.

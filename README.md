# lazy

![test](https://github.com/cnaebadi/lazy/actions/workflows/test.yml/badge.svg)

<p align="center">
  <img src="assets/banner.svg" alt="LAZY" width="320">
</p>

too lazy to type long commands.

```bash
./install.sh
./uninstall.sh
```

or:

```bash
curl -fsSL https://raw.githubusercontent.com/cnaebadi/lazy/main/install.sh | bash
```

works on **bash** & **zsh**.

## what

short functions for everyday shit:

`git` · `docker` · `k8s` · `laravel` · `postgres` · `redis` · `aws` · `os` · `node` · `composer`

```bash
gs            # git status
gps           # git push (default remote from config)
gps hamgit    # git push hamgit
gundo         # uncommit last (soft)
ni            # npm/yarn/pnpm install
cins          # composer install
dcu           # docker compose up -d
```

no aliases. only functions. config lives in `~/.config/lazy/lazy.conf`.

## config

```bash
mkdir -p ~/.config/lazy
cp /path/to/lazy/config/lazy.conf.example ~/.config/lazy/lazy.conf
# edit it. or don't. defaults are fine.
```

## contribute

read [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

i'm lazy. prs may sit. forever. maybe. don't take it personal.

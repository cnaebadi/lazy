# node (`n`)

prefix: **n** · needs: npm, yarn, pnpm, or bun

| command | does |
|---------|------|
| `ni` | install deps |
| `nadd lodash` | add package |
| `nr build` | run script |
| `nrd` | run `dev` script |
| `nrb` | run `build` script |
| `nt` | run `test` script |
| `nout` | list outdated packages |

maps to the active package manager:

| pm | `ni` | `nadd pkg` | `nr script` |
|----|------|------------|-------------|
| npm | `npm install` | `npm install pkg` | `npm run script` |
| yarn | `yarn install` | `yarn add pkg` | `yarn script` |
| pnpm | `pnpm install` | `pnpm add pkg` | `pnpm run script` |
| bun | `bun install` | `bun add pkg` | `bun run script` |

**config:** `NODE_PACKAGE_MANAGER` (`npm` \| `yarn` \| `pnpm` \| `bun`).

if unset, auto-detects first available pm in that order.

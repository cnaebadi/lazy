# docker (`d`)

prefix: **d** · needs: `docker`

| command | does |
|---------|------|
| `dps` | `docker ps` |
| `dps -a` | `docker ps -a` |
| `dcu` | `docker compose -f <file> up -d` |
| `dcu prod.yml` | override compose file (`.yml` / `.yaml` only) |
| `dcu --build` | flags pass through after optional file |
| `dcd` | `docker compose -f <file> down` |
| `dcr` | `docker compose -f <file> restart` |
| `dcr web` | restart service `web` |
| `dlogs` | `docker compose -f <file> logs -f` |
| `denter` | `exec -it` into the only running container |
| `denter web` | `exec -it web sh` |
| `denter web bash` | pick shell |

**config:** `DOCKER_COMPOSE_FILE` (default `docker-compose.yml`).

uses `docker compose` (v2) when available, falls back to `docker-compose`.

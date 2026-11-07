# Pandaria 5.4.8 Docker

Docker setup for a Mists of Pandaria 5.4.8 server (Legends of Azeroth + Playerbots) with MySQL, authserver, and worldserver. A single `./run.sh` boots the stack in order and waits for each service to be ready.

## Requires

- Docker with Compose v2
- MoP 5.4.8 client (`Data/` folder with MPQs, or download it via the `wow-downloader` service below)
- MoP `dbc`, `maps`, `vmaps`, `mmaps` (generated via the `maptools` service, see below)
- Server binaries: `authserver` and `worldserver`

## Setup

1. Provide the binaries (building takes hours, so prebuilt is recommended):

   - `authserver/authserver`
   - `worldserver/worldserver`

2. Configure environment:

   ```bash
   cp .env.example .env
   ```

    Set `WOW_DATA_FOLDER_PATH` in `.env` to your MoP client data path. It is required by the `maptools` service.

    If you downloaded via the `wow-downloader` service below, set it to the absolute path of `wow-downloader/Game` (client root containing `Data/`):

    ```bash
    WOW_DATA_FOLDER_PATH=/absolute/path/to/wow-downloader/Game
    ```

2b. Download client data (skip if you already own a 5.4.8 client):

    ```bash
    docker compose --profile wow-downloader up wow-downloader
    ```

    This runs minimal fetch first (`download-client.sh`, ~23 MB rar, seconds) then full fetch (`download.sh`, ~25 GB, hours) into `wow-downloader/Game/` (`wow-downloader/Game/Data/`, `wow-downloader/Game/Updates/`). Both steps are idempotent, safe to re-run to resume. Minimal populates base files, full fills per-file gaps.

    Options:

    ```bash
    # enUS only to save time/space
    LOCALES=enUS docker compose --profile wow-downloader up wow-downloader

    # ptBR only
    LOCALES=ptBR docker compose --profile wow-downloader up wow-downloader
    ```

    Or set `LOCALES` in `.env` (example in `.env.example`). The compose file defaults to `enUS ptBR` when unset.

    Notes:

    - Cinematics under `Data/<locale>/Interface/Cinematics/` are optional. The CDN currently returns 404 for them, the script warns and creates an empty zero-byte placeholder so in-game path references resolve. Reruns skip placeholders. They are not required for `maptools` extraction.
    - `wow-downloader/Game/` is git-ignored, safe for large binaries.

3. Generate game data via the `maptools` service:

   - Do not drop in externally extracted data. Extraction must be done via `maptools` so `dbc`, `maps`, `vmaps`, and `mmaps` match this build.
    - The `maptools` service is wired to run the extraction pipeline automatically (`command: ["bash", "/maptools/extract-all.sh"]` in `docker-compose.yml`).
   - Run it:

     ```bash
     docker compose --profile maptools up maptools
     ```

      This runs `mapextractor`, `vmap4extractor`, and `vmap4assembler` against `/client_data` (your `WOW_DATA_FOLDER_PATH`) and writes to `./maptools/data` on the host (`cameras`, `dbc`, `maps`, `vmaps`). `mmaps` generation is skipped by default because it takes several hours. `worldserver` consumes `./maptools/data` directly via its bind mount, no copy step needed.
    - For full generation including `mmaps`:

      ```bash
       docker compose --profile maptools run maptools bash /maptools/extract-all.sh --with-mmaps
      ```

4. Start everything:

   ```bash
   ./run.sh
   ```

## What `run.sh` does

Boots in order, waiting for each health log before continuing:

1. `db` - waits for `ready for connections`
   - Detects fresh init via `SQL init process done. Ready for start up` and sets a fresh-DB flag
2. `authserver` - waits for `Updating Realm List...`
3. `worldserver` - waits for `World initialized in`

On a fresh database it prints `Fresh database detected` at the end. See account creation below.

`run.sh` fails fast if `.env` is missing or if any `docker compose up` fails. Each wait polls `docker compose logs` every 3 seconds with no timeout.

## Services

| Service          | Port      | Notes                                  |
| ---------------- | --------- | ------------------------------------ |
| `db`             | none      | MySQL 8.0, root password `password`  |
| `authserver`     | `3724`    | Realm auth, config `authserver/*.conf` |
| `worldserver`    | `8085`    | World, config `worldserver/*.conf`    |
| `maptools`       | none      | Profile-only helper, see below         |
| `wow-downloader` | none      | Profile-only client fetcher, see below |

All services share the `pandaria-network` bridge. `authserver` and `worldserver` depend on `db`.

Useful commands:

```bash
docker compose ps
docker compose logs -f db
docker compose logs -f authserver
docker compose logs -f worldserver
```

## Persistence

MySQL data is persisted via bind mount:

```yaml
- ./mysqlserver/data:/var/lib/mysql
```

- First start hydrates `auth`, `characters`, `playerbots`, and `world` from the baked `/wowsql/*.sql` dumps. This takes a while.
- Later starts reuse the data and skip hydration via `mysqlserver/init-check.sh`.
- Full reset:

  ```bash
  docker compose down
  rm -rf ./mysqlserver/data
  ```

## Creating an account (first run)

Only needed on a fresh database, when `run.sh` prints `Fresh database detected`.

Attach to the worldserver console stdin:

```bash
docker compose attach worldserver
```

Create the base account and promote it to GM:

```
account create <username> <password>
account set gmlevel <username> 3 -1
```

Run `help account` inside the console if your build uses a different syntax.

Detach safely with `Ctrl-p` then `Ctrl-q`. Do not use `Ctrl-c`, it stops the worldserver.

## Client connection

Point your 5.4.8 client at the host running `authserver:3724`, usually by setting the realmlist to `127.0.0.1` for local play. Create the account first, then log in.

## Map tools (required for game data)

`dbc`, `maps`, `vmaps`, and `mmaps` must be generated with the `maptools` service. Do not skip this by reusing data extracted for another core or version.

### Download the client first

If you do not own a 5.4.8 client, use the `wow-downloader` service:

```bash
docker compose --profile wow-downloader up wow-downloader
```

What it does (`download-all.sh` runs minimal then full in sequence):

- `set -eu` fail-fast, `curl -f` so HTTP errors abort instead of saving error pages.
- Minimal step (`download-client.sh`, ~23 MB): extracts `"World of Warcraft 5.4.8 minimal"/` rar into `/data`, merging only missing files (never skips on `Data/`). `FORCE=1` overwrites everything.
- Full step (`download.sh`): downloads to `/data` in-container, bind-mounted to `wow-downloader/Game/` on host. Set `WOW_DATA_FOLDER_PATH` to `wow-downloader/Game` (client root) for `maptools`.
- Downloads `LOCALES` (default `enUS ptBR` via compose `${LOCALES:-enUS ptBR}`, override with `LOCALES=enUS` or `.env`). Each locale gets 6 speech/locale MPQs + 18 locale updates from the EU CDN path.
- Base MPQs, expansion MPQs, and base updates come from the NA CDN path.
- Partial files are removed on failure. Re-run resumes.
- Full layout: `Data/*.MPQ` (32), `Data/enUS/*.MPQ` (24), `Data/ptBR/*.MPQ` (24), `Updates/*.MPQ` (2), plus MFIL.

Then set in `.env`:

```bash
WOW_DATA_FOLDER_PATH=/absolute/path/to/wow-downloader/Game
```

### Extract game data

The service runs `bash /maptools/extract-all.sh` on `up` (orchestrator: `extract-maps.sh`, then `extract-vmaps.sh`, then `assemble-vmaps.sh`; single stages re-runnable on their own):

```bash
docker compose --profile maptools up maptools
```

Inside the container:

- `/maptools` - extractor binaries (`mapextractor`, `vmap4extractor`, `vmap4assembler`, `mmaps_generator`) plus scripts (`extract-maps.sh`, `extract-vmaps.sh`, `assemble-vmaps.sh`, `generate-mmaps.sh`, `extract-all.sh`)
- `/client_data` - your MoP client data from `WOW_DATA_FOLDER_PATH`
- Run output goes to `./maptools/data` on the host, which `worldserver` consumes directly via its bind mount (no copy step).

`mmaps` is skipped by default (takes several hours). Include it with:

```bash
      docker compose --profile maptools run maptools bash /maptools/extract-all.sh --with-mmaps
```

It mounts `./maptools` to `/maptools` and `${WOW_DATA_FOLDER_PATH}` to `/client_data`. The image builds from `./maptools/Dockerfile` (stock Ubuntu plus the Boost runtime the assembler/generator link against).

## Bot population & resource limits (60 bots / 5GB soft cap)

Tuned to stay under 5GB while keeping dungeon queues working. Bots stay logged in and roam, but expensive background systems are off or throttled.

| Area | File:Key | Value | Why |
| --- | --- | --- | --- |
| Population | `playerbots.conf: MinRandomBots / MaxRandomBots` | `60 / 60` | was 500 |
| Pool | `playerbots.conf: RotationPoolSize` | `60` | match online count |
| Accounts | `playerbots.conf: RandomBotAccountCount` | `200` kept | needs `> 60/10+50=56`, no reset needed |
| RAM cap | `docker-compose.yml: worldserver mem_limit / deploy.limits` | `5g / 5G` | hard max |
| RAM soft | `docker-compose.yml: worldserver mem_reservation / deploy.reservations` | `4g / 4G` | avoid OOM-kill, scheduler hint |
| Idle throttle | `playerbots.conf: BotActiveAlone / BotActiveAloneDurationSeconds` | `10 / 30` | only empty areas; near-player stays 100% via `BotActiveAloneForceWhen*` + `SmartScale` |
| Login smoothing | `playerbots.conf: RandomBotsPerInterval / RandomBotUpdateInterval` | `10 / 60` | avoid startup spike |
| Dungeons kept | `playerbots.conf: RandomBotJoinLfg / RandomBotGroupNearby / AutoDoQuests` | `1 / 1 / 1` | LFG fill still works |
| Disabled heavy | `playerbots.conf: RandomBotJoinBG` | `0` | no BG queue/teleport/combat |
| | `playerbots.conf: BgCheckInterval` | `120` | was 30 |
| | `playerbots.conf: DuelSpotSeedEnable` | `0` | kills re-level/re-gear/teleport sweep; `DuelSpotEnable` stays `1` |
| | `playerbots.conf: EnableRandomBotTrading` | `0` | no trade scans |
| | `playerbots.conf: RpgQuestHubSearchEnable` | `0` | no 2500yd giver scan |
| | `playerbots.conf: RoamTransports / RoamTransportCampChance` | `0 / 0` | no travel-graph/boat/zeppelin logic |
| | `playerbots.conf: AutoAvoidAoe / FastReactInBG` | `0 / 0` | no AoE avoidance tick |
| | `playerbots.conf: InviteChat / SayWhenCollectingItems` | `0 / 0` | no chat spam |
| Roam weights | `playerbots.conf: RpgStatusProbWeight.TravelFlight` | `0` | was 20, no taxis/cross-map |
| | `playerbots.conf: RpgStatusProbWeight.OutdoorPvp` | `0` | was 10 |
| | `playerbots.conf: RpgStatusProbWeight.DuelSpot` | `0` | was 10 |
| | `playerbots.conf: RpgStatusProbWeight.GoGrind` | `5` | was 15 |
| | `playerbots.conf: RpgStatusProbWeight.Rest` | `30` | was 8, more sitting |
| AI throttle | `playerbots.conf: IterationsPerTick / ReactDelay / RpgDelay` | `4 / 300 / 30000` | was `10 / 100 / 10000`, dumber but alive |
| Scan throttle | `playerbots.conf: SightDistance / ReactDistance / GrindDistance / RpgDistance / MaxMovementSearchTime` | `60.0 / 80.0 / 40.0 / 100 / 1` | was `100.0 / 150.0 / 75.0 / 200 / 3` |
| RAM saver | `worldserver.conf: DontCacheRandomMovementPaths` | `1` | less path cache for 5G; keep `GridUnload=1`, `MapUpdate.Threads=1` |

Apply:

```bash
docker compose up -d --force-recreate worldserver
docker stats worldserver --no-stream
```

If old 500 bots persist in DB, trim once with `.playerbot rndbot reset` in the worldserver console, then restart.

## Troubleshooting

- `ENV file not found` - copy `.env.example` to `.env` first.
- `worldserver` exits immediately - missing binaries or missing extracted content. Regenerate it via `maptools` (output is consumed directly from `./maptools/data`). Check `docker compose logs worldserver`.
- `authserver` never shows `Updating Realm List...` - `db` is still initializing, especially on first hydration. Wait and check `docker compose logs db`.
- Slow first boot is normal - multi-GB SQL hydration plus world init.
- Config belongs in `authserver/authserver.conf`, `worldserver/worldserver.conf`, and `worldserver/playerbots.conf`.
- `maptools` prints `No locales detected` - `WOW_DATA_FOLDER_PATH` points one level too deep. It must be the client root containing `Data/` (e.g. `.../wow-downloader/Game`), not `.../Game/Data`. The extractors build `<input>/Data/<locale>/locale-<locale>.MPQ` themselves.
- `maptools` repeats the old failure after fixing `.env` - compose reuses the existing container and its old mounts. Recreate it: `docker compose --profile maptools down --remove-orphans` then `up`, or `up --force-recreate`.
- `Found orphan containers ...` - stale containers from a renamed service or a second checkout. Clean with `down --remove-orphans`, and make sure you run compose from the edited checkout directory.
- Verify the mount before extracting: `docker compose --profile maptools run --rm maptools ls /client_data` should list `Data/ Updates/ *.mfil`; `ls /client_data/Data/enUS` should show `locale-enUS.MPQ`. If it shows bare MPQs at top level, the path is one level too deep (see above). If it is empty, the host path did not resolve (see Git Bash note below).
- `vmap4extractor` exits right after `Data/misc.MPQ` (or prints `/client_data/misc.MPQ` and stops) - it takes the `Data/` dir itself (`-d /client_data/Data/`, trailing slash required), unlike `mapextractor -i` which takes the client root. The script already handles this split; only manual invocations need care. If paths are right, suspect a truncated MPQ: delete it and re-run `wow-downloader` (it skips existing files and resumes).
- Stale `maptools/data/Buildings` from a failed run - `extract-vmaps.sh` removes it automatically on each run; if you invoke the tools by hand, `rm -rf ./maptools/data/Buildings` first.
- Manual extraction, one script per program (same invocations the orchestrator uses):
  ```bash
  docker compose --profile maptools run --rm maptools bash /maptools/extract-maps.sh
  docker compose --profile maptools run --rm maptools bash /maptools/extract-vmaps.sh
  docker compose --profile maptools run --rm maptools bash /maptools/assemble-vmaps.sh
  ```
  Raw binaries: `cd /maptools/data && /maptools/mapextractor -i /client_data` (client root), then `/maptools/vmap4extractor -d /client_data/Data/` (the `Data/` dir itself with trailing slash — vmap concatenates paths without a separator, unlike mapextractor), then `mkdir -p vmaps && /maptools/vmap4assembler Buildings vmaps`.
- `Missing Buildings directory, vmap extraction likely failed` (`assemble-vmaps.sh` guard) - `vmap4extractor` died earlier; scroll up past the assembler error for the real cause (usually input level or corrupt MPQ), fix that, then rerun. Never run the assembler standalone on a partial `Buildings/`.
- Git Bash `/c/...` paths - Docker Desktop usually resolves them, but if `/client_data` comes up empty, use a WSL2 Linux path or a quoted Windows path, then confirm with `docker compose config`.
- `worldserver` still missing `dbc/maps/vmaps` after a good extraction - restart it so it picks up the fresh mount content (`docker compose up worldserver -d --force-recreate`), and verify the `./maptools/data` bind mount resolves.

## Credits

- GIOdeBrito
- Legends of Azeroth
- danielsreichenbach

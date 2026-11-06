# Pandaria 5.4.8 Docker

Docker setup for a Mists of Pandaria 5.4.8 server (Legends of Azeroth + Playerbots) with MySQL, authserver, and worldserver. A single `./run.sh` boots the stack in order and waits for each service to be ready.

## Requires

- Docker with Compose v2
- MoP 5.4.8 client
- MoP `dbc`, `dbc2`, `maps`, `vmaps`, `mmaps` (generated via the `maptools` service, see below)
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

3. Generate game data via the `maptools` service:

   - Do not drop in externally extracted data. Extraction must be done via `maptools` so `dbc`, `maps`, `vmaps`, and `mmaps` match this build.
   - Start the helper container:

     ```bash
     docker compose --profile maptools up -d maptools
     docker compose exec maptools bash
     ```

   - Inside the container, `/maptools` holds `mapextractor`, `vmap4extractor`, `vmap4assembler`, and `mmaps_generator`, and `/client_data` holds your client data from `WOW_DATA_FOLDER_PATH`. Run the extractors from `/maptools` so output lands in `./maptools/data` on the host (`cameras`, `dbc`, `maps`, `vmaps`).
   - Copy the result into the worldserver data directory:

     ```bash
     cp -r ./maptools/data/* ./worldserver/data/
     ```

   - Alternative source for pre-extracted data: https://drive.google.com/file/d/1tnx-f8Ffourk9KEv_NkRts6htFQq3hnG/view

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

| Service      | Port      | Notes                                  |
| ------------ | --------- | ------------------------------------ |
| `db`         | none      | MySQL 8.0, root password `password`  |
| `authserver` | `3724`    | Realm auth, config `authserver/*.conf` |
| `worldserver`| `8085`    | World, config `worldserver/*.conf`    |
| `maptools`   | none      | Profile-only helper, see below         |

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

```bash
docker compose --profile maptools up -d maptools
docker compose exec maptools bash
```

Inside the container:

- `/maptools` - extractor binaries (`mapextractor`, `vmap4extractor`, `vmap4assembler`, `mmaps_generator`)
- `/client_data` - your MoP client data from `WOW_DATA_FOLDER_PATH`
- Run output goes to `./maptools/data` on the host, then copy it to `./worldserver/data` as described in Setup step 3.

It mounts `./maptools` to `/maptools` and `${WOW_DATA_FOLDER_PATH}` to `/client_data`.

## Troubleshooting

- `ENV file not found` - copy `.env.example` to `.env` first.
- `worldserver` exits immediately - missing binaries or missing `worldserver/data` content. Regenerate it via `maptools` and copy it to `worldserver/data`. Check `docker compose logs worldserver`.
- `authserver` never shows `Updating Realm List...` - `db` is still initializing, especially on first hydration. Wait and check `docker compose logs db`.
- Slow first boot is normal - multi-GB SQL hydration plus world init.
- Config belongs in `authserver/authserver.conf`, `worldserver/worldserver.conf`, and `worldserver/playerbots.conf`.

## Credits

- GIOdeBrito
- Legends of Azeroth
- danielsreichenbach

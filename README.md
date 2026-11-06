# Pandaria 5.4.8 Docker 

Requires 
- Docker
- MoP Client
- MoP Mmaps Vmaps

Download or either build the authserver and worldserver binaries (not recommended as they can take hours to build)

Within `worldserver/data` drop the extracted `dbc, dbc2, maps, vmaps`.
Example source: https://drive.google.com/file/d/1tnx-f8Ffourk9KEv_NkRts6htFQq3hnG/view

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

## Credits 

- GIOdeBrito
- Legends of Azeroth
- danielsreichenbach

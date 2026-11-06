#!/bin/sh

# Runs minimal client fetch then full MPQ fetch in sequence.
# Minimal (~23 MB) populates base files fast, full (~25 GB) fills the rest.
# Both steps are idempotent, safe to re-run. Full step must run second:
# download-client.sh skips when Game/Data exists, download.sh fills per-file gaps.
# Env passthrough: LOCALES, MINIMAL_URL, BASE_URL, FORCE, TARGET_DIR.

set -eu

/wow-downloader/download-client.sh
/wow-downloader/download.sh
echo "Done. Client in /data/"

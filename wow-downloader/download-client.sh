#!/bin/sh

# Downloads minimal MoP 5.4.8 client for maptools extraction.
# Runs inside wow-downloader service, writes to /data bind mount.
# Env: TARGET_DIR (default /data), MINIMAL_URL override, FORCE=1 to overwrite all.
# Merges only missing files by default, never skips based on Data/.
# Host data lands in ./wow-downloader/Game/ via compose volume.
# Alt full fetch lives in download.sh (~25 GB). This minimal rar is ~23 MB.
#
# Source: https://devil.tauri.hu/~kimbatt/minimal_548.rar
# Layout inside rar: "World of Warcraft 5.4.8 minimal"/ -> merged into Game/
#
# Manual run:
#   docker compose --profile wow-downloader run --rm wow-downloader bash /wow-downloader/download-client.sh
#   FORCE=1 to overwrite all files instead of merging missing ones.

set -eu

MINIMAL_URL="${MINIMAL_URL:-https://devil.tauri.hu/~kimbatt/minimal_548.rar}"
TARGET_DIR="${TARGET_DIR:-/data}"
FORCE="${FORCE:-}"
RAR_NAME="minimal_548.rar"
RAR_PATH="${TARGET_DIR}/${RAR_NAME}"
EXTRACT_DIR="/tmp/minimal_548_extract"
SRC_DIR="${EXTRACT_DIR}/World of Warcraft 5.4.8 minimal"

require_tool()
{
	if ! command -v "$1" >/dev/null 2>&1
	then
		echo "Missing required tool: $1" >&2
		exit 1
	fi
}

find_extractor()
{
	if command -v unrar >/dev/null 2>&1
	then
		echo "unrar"
		return 0
	fi

	if command -v 7z >/dev/null 2>&1
	then
		echo "7z"
		return 0
	fi

	if command -v 7zz >/dev/null 2>&1
	then
		echo "7zz"
		return 0
	fi

	echo "Missing required tool: unrar or 7z (packages unrar / p7zip-full)" >&2
	exit 1
}

download_rar()
{
	if [ -f "$RAR_PATH" ]
	then
		return 0
	fi

	mkdir -p "$TARGET_DIR"
	curl -fL# --retry 3 --retry-delay 5 --connect-timeout 20 "$MINIMAL_URL" -o "$RAR_PATH"
}

extract_rar()
{
	require_tool curl
	EXTRACTOR="$(find_extractor)"

	rm -rf "$EXTRACT_DIR"
	mkdir -p "$EXTRACT_DIR"

	if [ "$EXTRACTOR" = "unrar" ]
	then
		if ! "$EXTRACTOR" x -o+ "$RAR_PATH" "$EXTRACT_DIR/"
		then
			rm -rf "$EXTRACT_DIR"
			exit 1
		fi
	else
		if ! "$EXTRACTOR" x "$RAR_PATH" -o"$EXTRACT_DIR" -y
		then
			rm -rf "$EXTRACT_DIR"
			exit 1
		fi
	fi

	if [ ! -d "$SRC_DIR" ]
	then
		echo "Unexpected rar layout, missing: $SRC_DIR" >&2
		echo "Contents of $EXTRACT_DIR:" >&2
		ls -la "$EXTRACT_DIR" >&2
		exit 1
	fi
}

install_client()
{
	mkdir -p "$TARGET_DIR"
	cp -a "$SRC_DIR/." "$TARGET_DIR/"
}

install_missing()
{
	mkdir -p "$TARGET_DIR"

	(cd "$SRC_DIR" && find . -type d -print) | while IFS= read -r dir
	do
		mkdir -p "${TARGET_DIR}/${dir}"
	done

	(cd "$SRC_DIR" && find . -type f -print) | while IFS= read -r rel
	do
		if [ -f "${TARGET_DIR}/${rel}" ]
		then
			continue
		fi

		mkdir -p "$(dirname "${TARGET_DIR}/${rel}")"
		cp "$SRC_DIR/${rel}" "${TARGET_DIR}/${rel}"
		echo "Added missing: ${rel}"
	done
}

cleanup_success()
{
	rm -rf "$EXTRACT_DIR"
	rm -f "$RAR_PATH"
}

main()
{
	mkdir -p "$TARGET_DIR"
	download_rar
	extract_rar

	if [ "$FORCE" = "1" ]
	then
		echo "FORCE=1, overwriting ${TARGET_DIR}/"
		install_client
	else
		echo "Merging missing files into ${TARGET_DIR}/"
		install_missing
	fi

	cleanup_success
	echo "Done. Minimal client in ${TARGET_DIR}/"
}

main

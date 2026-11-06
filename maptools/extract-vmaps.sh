#!/bin/bash
set -euo pipefail

TOOLS_DIR="/maptools"
CLIENT_DATA="/client_data"
OUTPUT_DIR="/maptools/data"

usage()
{
	echo "Usage: extract-vmaps.sh [--help]"
	echo ""
	echo "Extract vmaps via vmap4extractor (produces Buildings/)."
	echo ""
	echo "Options:"
	echo "  -h, --help     Show this help"
	echo ""
	echo "Expected mounts:"
	echo "  $TOOLS_DIR  - extractor binaries"
	echo "  $CLIENT_DATA - MoP 5.4.8 client root folder, containing Data/ (WOW_DATA_FOLDER_PATH)"
	echo "  $OUTPUT_DIR - extraction output (host ./maptools/data)"
}

require_dir()
{
	if [[ ! -d "$1" ]]; then
		echo "Missing directory: $1" >&2
		exit 1
	fi
}

require_file()
{
	if [[ ! -f "$1" ]]; then
		echo "Missing file: $1" >&2
		exit 1
	fi
}

require_non_empty_dir()
{
	if [[ -z "$(ls -A "$1")" ]]; then
		echo "Empty directory: $1" >&2
		exit 1
	fi
}

ensure_executable()
{
	if [[ ! -x "$1" ]]; then
		chmod +x "$1"
	fi
}

require_client_data()
{
	require_dir "$CLIENT_DATA"
	require_non_empty_dir "$CLIENT_DATA"
	if [[ ! -d "$CLIENT_DATA/Data" ]]; then
		echo "Invalid client folder: $CLIENT_DATA/Data not found." >&2
		echo "WOW_DATA_FOLDER_PATH must point at the client root (containing Data/), not at Data/ itself." >&2
		ls -la "$CLIENT_DATA" >&2
		exit 1
	fi
	if [[ ! -d "$CLIENT_DATA/Data/enUS" && ! -d "$CLIENT_DATA/Data/ptBR" && ! -d "$CLIENT_DATA/Data/enGB" && ! -d "$CLIENT_DATA/Data/deDE" && ! -d "$CLIENT_DATA/Data/frFR" && ! -d "$CLIENT_DATA/Data/esES" && ! -d "$CLIENT_DATA/Data/esMX" && ! -d "$CLIENT_DATA/Data/itIT" && ! -d "$CLIENT_DATA/Data/koKR" && ! -d "$CLIENT_DATA/Data/ptPT" && ! -d "$CLIENT_DATA/Data/ruRU" && ! -d "$CLIENT_DATA/Data/zhCN" && ! -d "$CLIENT_DATA/Data/zhTW" ]]; then
		echo "No locales detected under $CLIENT_DATA/Data (expected locale subfolder with locale-*.MPQ)." >&2
		ls -la "$CLIENT_DATA/Data" >&2
		exit 1
	fi
}

main()
{
	for arg in "$@"; do
		case "$arg" in
			-h|--help)
				usage
				exit 0
				;;
			*)
				echo "Unknown option: $arg" >&2
				usage >&2
				exit 1
				;;
		esac
	done

	require_dir "$TOOLS_DIR"
	require_client_data
	mkdir -p "$OUTPUT_DIR"
	require_dir "$OUTPUT_DIR"

	rm -rf "$OUTPUT_DIR/Buildings"

	require_file "$TOOLS_DIR/vmap4extractor"
	ensure_executable "$TOOLS_DIR/vmap4extractor"

	echo "Extracting vmaps..."
	cd "$OUTPUT_DIR"

	echo "Running: vmap4extractor -d $CLIENT_DATA/Data/"
	# NOTE: vmap4extractor concatenates its input path directly (no separator,
	# no Data/ prefix), unlike mapextractor -i which takes the client root.
	# The trailing slash is load-bearing: "$CLIENT_DATA/Data/" only.
	"$TOOLS_DIR/vmap4extractor" -d "$CLIENT_DATA/Data/"
}

main "$@"

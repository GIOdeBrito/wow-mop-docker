#!/bin/bash
set -euo pipefail

TOOLS_DIR="/maptools"
CLIENT_DATA="/client_data"
OUTPUT_DIR="/maptools/data"
WITH_MMAPS=0

usage()
{
	echo "Usage: extract-map.sh [--with-mmaps] [--help]"
	echo ""
	echo "Extract dbc, maps, vmaps via maptools. mmaps generation is optional (takes several hours)."
	echo ""
	echo "Options:"
	echo "  --with-mmaps   Also run mmaps_generator (slow, several hours)"
	echo "  -h, --help     Show this help"
	echo ""
	echo "Expected mounts:"
	echo "  $TOOLS_DIR  - extractor binaries"
	echo "  $CLIENT_DATA - MoP 5.4.8 client root folder, containing Data/ (WOW_DATA_FOLDER_PATH)"
	echo "  $OUTPUT_DIR - extraction output (host ./maptools/data)"
}

parse_args()
{
	for arg in "$@"; do
		case "$arg" in
			--with-mmaps)
				WITH_MMAPS=1
				;;
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

run_mapextractor()
{
	echo "Extracting dbc/maps/cameras..."
	cd "$OUTPUT_DIR"

	if "$TOOLS_DIR/mapextractor" --help 2>&1 | grep -q -- "-i"; then
		"$TOOLS_DIR/mapextractor" -i "$CLIENT_DATA"
		return
	fi

	"$TOOLS_DIR/mapextractor"
}

run_vmap_extractor()
{
	echo "Extracting vmaps..."
	cd "$OUTPUT_DIR"

	if "$TOOLS_DIR/vmap4extractor" --help 2>&1 | grep -q -- "-i"; then
		"$TOOLS_DIR/vmap4extractor" -i "$CLIENT_DATA"
		return
	fi

	"$TOOLS_DIR/vmap4extractor"
}

run_vmap_assembler()
{
	echo "Assembling vmaps..."
	cd "$OUTPUT_DIR"

	if [[ ! -d "Buildings" ]]; then
		echo "Missing Buildings directory, vmap extraction likely failed." >&2
		exit 1
	fi

	mkdir -p vmaps
	"$TOOLS_DIR/vmap4assembler" Buildings vmaps
}

run_mmaps_generator()
{
	echo "Generating mmaps (takes several hours)..."
	cd "$OUTPUT_DIR"
	mkdir -p mmaps
	"$TOOLS_DIR/mmaps_generator"
}

main()
{
	parse_args "$@"

	require_dir "$TOOLS_DIR"
	require_dir "$CLIENT_DATA"
	require_non_empty_dir "$CLIENT_DATA"
	if [[ ! -d "$CLIENT_DATA/Data" ]]; then
		echo "Invalid client folder: $CLIENT_DATA/Data not found." >&2
		echo "WOW_DATA_FOLDER_PATH must point at the client root (containing Data/), not at Data/ itself." >&2
		ls -la "$CLIENT_DATA" >&2
		exit 1
	fi
	if [[ ! -d "$CLIENT_DATA/Data/enUS" && ! -d "$CLIENT_DATA/Data/ptBR" && ! -d "$CLIENT_DATA/Data/enGB" && ! -d "$CLIENT_DATA/Data/deDE" && ! -d "$CLIENT_DATA/Data/frFR" ]]; then
		echo "No locales detected under $CLIENT_DATA/Data (expected enUS/ptBR subfolder with locale-*.MPQ)." >&2
		ls -la "$CLIENT_DATA/Data" >&2
		exit 1
	fi
	mkdir -p "$OUTPUT_DIR"
	require_dir "$OUTPUT_DIR"

	rm -rf "$OUTPUT_DIR/Buildings"

	require_file "$TOOLS_DIR/mapextractor"
	require_file "$TOOLS_DIR/vmap4extractor"
	require_file "$TOOLS_DIR/vmap4assembler"

	ensure_executable "$TOOLS_DIR/mapextractor"
	ensure_executable "$TOOLS_DIR/vmap4extractor"
	ensure_executable "$TOOLS_DIR/vmap4assembler"

	run_mapextractor
	run_vmap_extractor
	run_vmap_assembler

	if [[ "$WITH_MMAPS" -eq 0 ]]; then
		echo "Skipping mmaps_generator (takes several hours). Re-run with --with-mmaps to include it."
		echo "Done. Copy $OUTPUT_DIR/* to worldserver/data/ on the host."
		return
	fi

	require_file "$TOOLS_DIR/mmaps_generator"
	ensure_executable "$TOOLS_DIR/mmaps_generator"
	run_mmaps_generator

	echo "Done. Copy $OUTPUT_DIR/* to worldserver/data/ on the host."
}

main "$@"

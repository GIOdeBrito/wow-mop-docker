#!/bin/bash
set -euo pipefail

TOOLS_DIR="/maptools"
OUTPUT_DIR="/maptools/data"

usage()
{
	echo "Usage: generate-mmaps.sh [--help]"
	echo ""
	echo "Generate mmaps via mmaps_generator (takes several hours)."
	echo ""
	echo "Options:"
	echo "  -h, --help     Show this help"
	echo ""
	echo "Expected mounts:"
	echo "  $TOOLS_DIR  - extractor binaries"
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

ensure_executable()
{
	if [[ ! -x "$1" ]]; then
		chmod +x "$1"
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
	mkdir -p "$OUTPUT_DIR"
	require_dir "$OUTPUT_DIR"

	require_file "$TOOLS_DIR/mmaps_generator"
	ensure_executable "$TOOLS_DIR/mmaps_generator"

	echo "Generating mmaps (takes several hours)..."
	cd "$OUTPUT_DIR"

	echo "Running: mmaps_generator"
	mkdir -p mmaps
	"$TOOLS_DIR/mmaps_generator"
}

main "$@"

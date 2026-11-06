#!/bin/bash
set -euo pipefail

TOOLS_DIR="/maptools"
OUTPUT_DIR="/maptools/data"

usage()
{
	echo "Usage: assemble-vmaps.sh [--help]"
	echo ""
	echo "Assemble vmaps via vmap4assembler (Buildings/ -> vmaps/)."
	echo ""
	echo "Options:"
	echo "  -h, --help     Show this help"
	echo ""
	echo "Expected mounts:"
	echo "  $TOOLS_DIR  - extractor binaries"
	echo "  $OUTPUT_DIR - extraction output (host ./maptools/data), must contain Buildings/"
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
	require_dir "$OUTPUT_DIR"

	if [[ ! -d "$OUTPUT_DIR/Buildings" ]]; then
		echo "Missing Buildings directory, vmap extraction likely failed." >&2
		exit 1
	fi

	require_file "$TOOLS_DIR/vmap4assembler"
	ensure_executable "$TOOLS_DIR/vmap4assembler"

	echo "Assembling vmaps..."
	cd "$OUTPUT_DIR"

	echo "Running: vmap4assembler Buildings vmaps"
	mkdir -p vmaps
	"$TOOLS_DIR/vmap4assembler" Buildings vmaps
}

main "$@"

#!/bin/bash
set -euo pipefail

TOOLS_DIR="/maptools"
OUTPUT_DIR="/maptools/data"
WITH_MMAPS=0

usage()
{
	echo "Usage: extract-all.sh [--with-mmaps] [--help]"
	echo ""
	echo "Extract dbc, maps, vmaps via maptools. mmaps generation is optional (takes several hours)."
	echo ""
	echo "Options:"
	echo "  --with-mmaps   Also run mmaps_generator (slow, several hours)"
	echo "  -h, --help     Show this help"
	echo ""
	echo "Expected mounts:"
	echo "  $TOOLS_DIR  - extractor binaries"
	echo "  $OUTPUT_DIR - extraction output (host ./maptools/data)"
	echo ""
	echo "Runs, in order: extract-maps.sh, extract-vmaps.sh, assemble-vmaps.sh"
	echo "and optionally generate-mmaps.sh."
}

main()
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

	"$TOOLS_DIR/extract-maps.sh"
	"$TOOLS_DIR/extract-vmaps.sh"
	"$TOOLS_DIR/assemble-vmaps.sh"

	if [[ "$WITH_MMAPS" -eq 0 ]]; then
		echo "Skipping mmaps_generator (takes several hours). Re-run with --with-mmaps to include it."
		echo "Done. Copy $OUTPUT_DIR/* to worldserver/data/ on the host."
		return
	fi

	"$TOOLS_DIR/generate-mmaps.sh"

	echo "Done. Copy $OUTPUT_DIR/* to worldserver/data/ on the host."
}

main "$@"

#!/bin/sh

# Downloads MoP 5.4.8 client data for maptools extraction.
# Runs inside wow-downloader service, writes to /data bind mount.
# Env: LOCALES (default "enUS ptBR"), BASE_URL override.
# Host data lands in ./maptools/data_wow/ via compose volume.
#
# Original author: @danielsreichenbach danielsreichenbach
# Original source: https://gist.github.com/danielsreichenbach/3e56a6b0a6697742955b39e10e2d32e8

set -eu

BASE_URL="${BASE_URL:-http://dist.blizzard.com.edgesuite.net}"
TARGET_DIR="/data"
LOCALES="${LOCALES:-enUS ptBR}"
MFIL="wow-18414-447E3E618F731CCBF4F7D2C4E56C5644.mfil"

if [ -z "$LOCALES" ]
then
	echo "LOCALES must not be empty" >&2
	exit 1
fi

download_if_missing()
{
	if [ -f "$2" ]
	then
		return 0
	fi

	mkdir -p "$(dirname "$2")"

	if ! curl -fL# --retry 3 --retry-delay 5 --connect-timeout 20 "$1" -o "$2"
	then
		rm -f "$2"
		exit 1
	fi
}

download_optional()
{
	if [ -f "$2" ]
	then
		return 0
	fi

	mkdir -p "$(dirname "$2")"

	if ! curl -fL# --retry 2 --retry-delay 5 --connect-timeout 20 "$1" -o "$2"
	then
		echo "Warning: optional file not found, skipping $1" >&2
		rm -f "$2"
		return 0
	fi
}

validate_locale()
{
	case "$1" in
		""|*/*|*..*)
			echo "Invalid locale: '$1'" >&2
			exit 1
			;;
	esac
}

fetch_mfil()
{
	echo "Fetching 5.4.8 MFIL to ${TARGET_DIR}/${MFIL}"
	download_if_missing "${BASE_URL}/wow-pod-retail/NA/15890.direct/${MFIL}" "${TARGET_DIR}/${MFIL}"
}

download_base_archives()
{
	echo "Downloading base data files..."

	for archive in alternate.MPQ base-OSX.MPQ base-Win.MPQ interface.MPQ itemtexture.MPQ misc.MPQ model.MPQ sound.MPQ texture.MPQ world.MPQ
	do
		echo "Downloading ${archive} to ${TARGET_DIR}/Data/${archive}"
		download_if_missing "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" "${TARGET_DIR}/Data/${archive}"
	done
}

download_expansion_archives()
{
	echo "Downloading expansion data files..."

	for archive in expansion1.MPQ expansion2.MPQ expansion3.MPQ expansion4.MPQ
	do
		echo "Downloading ${archive} to ${TARGET_DIR}/Data/${archive}"
		download_if_missing "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" "${TARGET_DIR}/Data/${archive}"
	done
}

download_base_updates()
{
	echo "Downloading base update files..."

	for archive in wow-update-base-16016.MPQ wow-update-base-16048.MPQ wow-update-base-16057.MPQ wow-update-base-16309.MPQ wow-update-base-16357.MPQ wow-update-base-16516.MPQ wow-update-base-16650.MPQ wow-update-base-16844.MPQ wow-update-base-16965.MPQ wow-update-base-17116.MPQ wow-update-base-17266.MPQ wow-update-base-17325.MPQ wow-update-base-17345.MPQ wow-update-base-17538.MPQ wow-update-base-17645.MPQ wow-update-base-17688.MPQ wow-update-base-17898.MPQ wow-update-base-18273.MPQ
	do
		echo "Downloading ${archive} to ${TARGET_DIR}/Data/${archive}"
		download_if_missing "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" "${TARGET_DIR}/Data/${archive}"
	done
}

download_final_updates()
{
	echo "Downloading final update files..."
	mkdir -p "${TARGET_DIR}/Updates"

	for archive in wow-0-18414-OSX-final.MPQ wow-0-18414-Win-final.MPQ
	do
		echo "Downloading ${archive} to ${TARGET_DIR}/Updates/${archive}"
		download_if_missing "${BASE_URL}/wow-pod-retail/NA/15890.direct/Updates/${archive}" "${TARGET_DIR}/Updates/${archive}"
	done
}

download_locale_archives()
{
	echo "Downloading $1 locale archives..."

	for archive in "expansion1-speech-$1.MPQ" "expansion2-speech-$1.MPQ" "expansion3-speech-$1.MPQ" "expansion4-speech-$1.MPQ" "locale-$1.MPQ" "speech-$1.MPQ"
	do
		echo "Downloading ${archive} to ${TARGET_DIR}/Data/$1/${archive}"
		# Upstream hosts locale MPQs under EU path, keep EU here.
		download_if_missing "${BASE_URL}/wow-pod-retail/EU/15890.direct/Data/$1/${archive}" "${TARGET_DIR}/Data/$1/${archive}"
	done
}

download_locale_updates()
{
	echo "Downloading $1 locale updates..."

	for update in "wow-update-$1-16016.MPQ" "wow-update-$1-16048.MPQ" "wow-update-$1-16057.MPQ" "wow-update-$1-16309.MPQ" "wow-update-$1-16357.MPQ" "wow-update-$1-16516.MPQ" "wow-update-$1-16650.MPQ" "wow-update-$1-16844.MPQ" "wow-update-$1-16965.MPQ" "wow-update-$1-17116.MPQ" "wow-update-$1-17266.MPQ" "wow-update-$1-17325.MPQ" "wow-update-$1-17345.MPQ" "wow-update-$1-17538.MPQ" "wow-update-$1-17645.MPQ" "wow-update-$1-17688.MPQ" "wow-update-$1-17898.MPQ" "wow-update-$1-18273.MPQ"
	do
		echo "Downloading ${update} to ${TARGET_DIR}/Data/$1/${update}"
		# Upstream hosts locale MPQs under EU path, keep EU here.
		download_if_missing "${BASE_URL}/wow-pod-retail/EU/15890.direct/Data/$1/${update}" "${TARGET_DIR}/Data/$1/${update}"
	done
}

download_cinematics()
{
	echo "Downloading $1 cinematics (optional, skipped on 404)..."
	mkdir -p "${TARGET_DIR}/Data/$1/Interface/Cinematics"

	for movie in DSI_Act1_1280.avi DSI_Act1_800.avi DSI_Act2_1280.avi DSI_Act2_800.avi DSI_Act3_1280.avi DSI_Act3_800.avi DSI_Act4_1280.avi DSI_Act4_800.avi Goblin_1280.avi Goblin_800.avi Goblin.mp3 Goblin.sbt Logo_1024.avi Logo_800.avi Worgen_1280.avi Worgen_800.avi Worgen.mp3 Worgen.sbt WoW3X_Intro_1280.avi WoW3X_Intro_800.avi WoW3X_Intro.mp3 WoW3X_Intro.sbt WOW_FotLK_1024.avi WOW_FotLK_800.avi WOW_Intro_1024.avi WOW_Intro_800.avi WOW_Intro_BC_1024.avi WOW_Intro_BC_800.avi WOW_Intro_LK_1280.avi WOW_Intro_LK_800.avi WoW_Intro_LK.mp3 WoW_Intro_LK.sbt WOW_Wrathgate_1280.avi WOW_Wrathgate_800.avi WOW_Wrathgate.mp3 WoW_Wrathgate.sbt
	do
		echo "Downloading ${movie} to ${TARGET_DIR}/Data/$1/Interface/Cinematics/${movie}"
		# Cinematics are not required for maptools extraction, skip missing files.
		download_optional "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/$1/Interface/Cinematics/${movie}" "${TARGET_DIR}/Data/$1/Interface/Cinematics/${movie}"
	done
}

download_locales()
{
	echo "Downloading localization files..."

	for locale in $LOCALES
	do
		validate_locale "$locale"
		mkdir -p "${TARGET_DIR}/Data/${locale}/" "${TARGET_DIR}/Data/${locale}/Interface/Cinematics/"
		download_locale_archives "$locale"
		download_locale_updates "$locale"
		download_cinematics "$locale"
	done
}

main()
{
	mkdir -p "$TARGET_DIR"
	fetch_mfil
	download_base_archives
	download_expansion_archives
	download_base_updates
	download_final_updates
	download_locales
	echo "Done. Client data in ${TARGET_DIR}/"
}

main

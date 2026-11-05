#!/bin/sh

# Author: @danielsreichenbach danielsreichenbach
# Source: https://gist.github.com/danielsreichenbach/3e56a6b0a6697742955b39e10e2d32e8

echo "Fetching 5.4.8 MFIL"
BASE_URL="http://dist.blizzard.com.edgesuite.net"
if [ ! -f "wow-18414-447E3E618F731CCBF4F7D2C4E56C5644.mfil" ]; then
    curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/wow-18414-447E3E618F731CCBF4F7D2C4E56C5644.mfil" -o "wow-18414-447E3E618F731CCBF4F7D2C4E56C5644.mfil"
fi

echo "Creating game folder 5.4.8"
mkdir -p 5.4.8
cd 5.4.8 || exit

echo "Downloading data files..."
mkdir -p Data/
for archive in alternate.MPQ base-OSX.MPQ base-Win.MPQ interface.MPQ itemtexture.MPQ misc.MPQ model.MPQ sound.MPQ texture.MPQ world.MPQ ; do
    echo "Downloading ${archive} to Data/${archive}"
    if [ ! -f "Data/${archive}" ]; then
        curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" -o "Data/${archive}"
    fi
done

for archive in expansion1.MPQ expansion2.MPQ expansion3.MPQ expansion4.MPQ ; do
    echo "Downloading ${archive} to Data/${archive}"
    if [ ! -f "Data/${archive}" ]; then
        curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" -o "Data/${archive}"
    fi
done

echo "Downloading update files..."
for archive in wow-update-base-16016.MPQ wow-update-base-16048.MPQ wow-update-base-16057.MPQ wow-update-base-16309.MPQ wow-update-base-16357.MPQ wow-update-base-16516.MPQ wow-update-base-16650.MPQ wow-update-base-16844.MPQ wow-update-base-16965.MPQ wow-update-base-17116.MPQ wow-update-base-17266.MPQ wow-update-base-17325.MPQ wow-update-base-17345.MPQ wow-update-base-17538.MPQ wow-update-base-17645.MPQ wow-update-base-17688.MPQ wow-update-base-17898.MPQ wow-update-base-18273.MPQ ; do
    echo "Downloading ${archive} to Data/${archive}"
    if [ ! -f "Data/${archive}" ]; then
        curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${archive}" -o "Data/${archive}"
    fi
done

mkdir -p Updates/
for archive in wow-0-18414-OSX-final.MPQ wow-0-18414-Win-final.MPQ ; do
    echo "Downloading ${archive} to Updates/${archive}"
    if [ ! -f "Updates/${archive}" ]; then
        curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/Updates/${archive}" -o "Updates/${archive}"
    fi
done

echo "Downloading localization files..."
for locale in enUS ptBR ; do
    echo "Downloading ${locale} localization files..."
    mkdir -p "Data/${locale}/" "Data/${locale}/Interface/Cinematics/"

    for archive in "expansion1-speech-${locale}.MPQ" "expansion2-speech-${locale}.MPQ" "expansion3-speech-${locale}.MPQ" "expansion4-speech-${locale}.MPQ" "locale-${locale}.MPQ" "speech-${locale}.MPQ" ; do
        echo "Downloading ${archive} to Data/${locale}/${archive}"

        if [ ! -f "Data/${locale}/${archive}" ]; then
            curl -L# "${BASE_URL}/wow-pod-retail/EU/15890.direct/Data/${locale}/${archive}" -o "Data/${locale}/${archive}"
        fi
    done

    for update in "wow-update-${locale}-16016.MPQ" "wow-update-${locale}-16048.MPQ" "wow-update-${locale}-16057.MPQ" "wow-update-${locale}-16309.MPQ" "wow-update-${locale}-16357.MPQ" "wow-update-${locale}-16516.MPQ" "wow-update-${locale}-16650.MPQ" "wow-update-${locale}-16844.MPQ" "wow-update-${locale}-16965.MPQ" "wow-update-${locale}-17116.MPQ" "wow-update-${locale}-17266.MPQ" "wow-update-${locale}-17325.MPQ" "wow-update-${locale}-17345.MPQ" "wow-update-${locale}-17538.MPQ" "wow-update-${locale}-17645.MPQ" "wow-update-${locale}-17688.MPQ" "wow-update-${locale}-17898.MPQ" "wow-update-${locale}-18273.MPQ" ; do
        echo "Downloading ${update} to Data/${locale}/${update}"

        if [ ! -f "Data/${locale}/${update}" ]; then
            curl -L# "${BASE_URL}/wow-pod-retail/EU/15890.direct/Data/${locale}/${update}" -o "Data/${locale}/${update}"
        fi
    done

    for movie in DSI_Act1_1280.avi DSI_Act1_800.avi DSI_Act2_1280.avi DSI_Act2_800.avi DSI_Act3_1280.avi DSI_Act3_800.avi DSI_Act4_1280.avi DSI_Act4_800.avi Goblin_1280.avi Goblin_800.avi Goblin.mp3 Goblin.sbt Logo_1024.avi Logo_800.avi Worgen_1280.avi Worgen_800.avi Worgen.mp3 Worgen.sbt WoW3X_Intro_1280.avi WoW3X_Intro_800.avi WoW3X_Intro.mp3 WoW3X_Intro.sbt WOW_FotLK_1024.avi WOW_FotLK_800.avi WOW_Intro_1024.avi WOW_Intro_800.avi WOW_Intro_BC_1024.avi WOW_Intro_BC_800.avi WOW_Intro_LK_1280.avi WOW_Intro_LK_800.avi WoW_Intro_LK.mp3 WoW_Intro_LK.sbt WOW_Wrathgate_1280.avi WOW_Wrathgate_800.avi WOW_Wrathgate.mp3 WoW_Wrathgate.sbt ; do
        echo "Download ${movie} Data/${locale}/Interface/Cinematics/${movie}"
        if [ ! -f "Data/${locale}/Interface/Cinematics/${movie}" ]; then
            curl -L# "${BASE_URL}/wow-pod-retail/NA/15890.direct/Data/${locale}/Interface/Cinematics/${movie}" -o "Data/${locale}/Interface/Cinematics/${movie}"
        fi
    done
done

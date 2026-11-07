#!/bin/bash

echo ""
echo "Running GIO's WoW Mists of Pandaria Linux service"
echo ""

if [[ ! -f ".env" ]]; then
	echo "ENV file not found. Clone the \".env.example\" file and try again."
	exit 1
fi

# Verify if auth and worldserver's binaries are in their proper folders
if [[ ! -f "authserver/authserver" ]]; then
	echo "authserver binary not found at authserver/authserver. Provide prebuilt binary (see README Setup step 1) and try again."
	exit 1
fi

if [[ ! -f "worldserver/worldserver" ]]; then
	echo "worldserver binary not found at worldserver/worldserver. Provide prebuilt binary (see README Setup step 1) and try again."
	exit 1
fi

# Warn that the map extraction tools are not in maptools/
if [[ ! -f "maptools/mapextractor" ]]; then
	echo "WARNING: maptools binary not found at maptools/mapextractor. Extraction via maptools service will fail."
fi

if [[ ! -f "maptools/vmap4extractor" ]]; then
	echo "WARNING: maptools binary not found at maptools/vmap4extractor. Extraction via maptools service will fail."
fi

if [[ ! -f "maptools/vmap4assembler" ]]; then
	echo "WARNING: maptools binary not found at maptools/vmap4assembler. Extraction via maptools service will fail."
fi

if [[ ! -f "maptools/mmaps_generator" ]]; then
	echo "WARNING: maptools binary not found at maptools/mmaps_generator. Extraction via maptools service will fail."
fi

printf "\n\n"

echo "Starting MySQL database..."

if ! docker compose up db -d; then
	echo "Failed to start MySQL database."
	exit 1
fi

echo "Waiting for database..."

FRESH_DB=0

while true; do
	DB_LOGS=$(docker compose logs db 2>&1)

	if echo "$DB_LOGS" | grep -qF "SQL init process done. Ready for start up"; then
		FRESH_DB=1
	fi

	if echo "$DB_LOGS" | grep -qE "ready for connections"; then
		break
	fi

	sleep 3
done

echo "Database is ready."
echo "Starting authserver..."

if ! docker compose up authserver -d; then
	echo "Failed to start authserver."
	exit 1
fi

echo "Waiting for authserver..."

while true; do
	if docker compose logs authserver 2>&1 | grep -qF "Updating Realm List..."; then
		break
	fi

	sleep 3

	CID=$(docker compose ps -q authserver)
	if [[ -z "$CID" ]] || ! docker inspect -f '{{.State.Running}}' "$CID" 2>/dev/null | grep -q "true"; then
		echo "authserver exited abruptly, restarting..."
		docker compose up authserver -d
	fi
done

echo "Authserver is ready."
echo "Starting worldserver..."

if ! docker compose up worldserver -d; then
	echo "Failed to start worldserver."
	exit 1
fi

echo "Waiting for worldserver..."

while true; do
	if docker compose logs worldserver 2>&1 | grep -qF "World initialized in"; then
		break
	fi

	sleep 3
done

echo "Worldserver is ready."

if [[ "$FRESH_DB" -eq 1 ]]; then
	echo "Fresh database detected. You should create a base account."
fi

echo "All done. You can go play now."


#!/bin/bash

echo ""
echo "Running GIO's WoW Mists of Pandaria Linux service"
echo ""

if [[ ! -f ".env" ]]; then
	echo "ENV file not found. Clone the \".env.example\" file and try again."
	exit 1
fi

echo "Starting MySQL database..."

if ! docker compose up db -d; then
	echo "Failed to start MySQL database."
	exit 1
fi

echo "Waiting for database..."

while true; do
	if docker compose logs db 2>&1 | grep -qE "ready for connections"; then
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

echo "All done. You can go play now."


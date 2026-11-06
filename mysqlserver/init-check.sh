#!/usr/bin/env bash

set -e

if mysql -u root -ppassword -e "show databases;" | grep -qw auth; then
	printf "[INIT CHECK] Databases are set. Skip setup\n"
else
	printf "[INIT CHECK] Databases are missing. Setting up...\n"

	# Create databases
	mysql -u root -ppassword < /giosql/0000-init.sql

	# Hydrate databases
	mysql -u root -ppassword auth < /wowsql/auth.sql
	mysql -u root -ppassword characters < /wowsql/characters.sql
	mysql -u root -ppassword playerbots < /wowsql/playerbots.sql
	mysql -u root -ppassword world < /wowsql/world.sql

	printf "[INIT CHECK] DB is set\n"
fi
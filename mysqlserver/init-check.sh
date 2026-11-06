#!/usr/bin/env bash

set -e

if mysql -u root -ppassword -e "show databases;" | grep -qw auth; then
	printf "[INIT CHECK] Databases are all set. Skipping setup...\n"
else
	printf "[INIT CHECK] Databases are missing. Setting up...\n"

	# Create databases
	mysql -u root -ppassword < /giosql/0000-init.sql

	# Hydrate databases
	
	printf "[INIT CHECK] Importing auth...\n"
	mysql -u root -ppassword auth < /wowsql/auth.sql
	
	printf "[INIT CHECK] Importing characters...\n"
	mysql -u root -ppassword characters < /wowsql/characters.sql
	
	printf "[INIT CHECK] Importing playerbots...\n"
	mysql -u root -ppassword playerbots < /wowsql/playerbots.sql
	
	printf "[INIT CHECK] Importing world...\n"
	mysql -u root -ppassword world < /wowsql/world.sql

	printf "[INIT CHECK] DB is set\n"
fi
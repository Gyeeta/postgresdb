#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

if [ ! -f /postgresdb/rundb.sh ] || [ ! -f /postgresdb/db_install.sh ]; then
	echo -e "\n\nERROR : Invalid postgresdb container image as /postgresdb/rundb.sh or /postgresdb/db_install.sh files not found...\n\n"
	exit 1
fi

cd /postgresdb

trap 'echo "	Exiting now... Cleaning up..."; ./rundb.sh stop; exit 0' SIGINT SIGQUIT SIGTERM

DBDIR=/dbdata

CMD=${1:-"start"}

shift

if [ "$CMD" = "--initdb" ]; then
	if [ ! -d $DBDIR ]; then
		echo -e "\n\nMissing Persistent Volume for Gyeeta's Postgres DB. Please mount a persistent volume of at least 50 GB free space at $DBDIR container mount point.\n\n"
		exit 1
	fi

	if [ -f ${DBDIR}/gyeetadb/gy_install.cfg 2> /dev/null ] && [ -f ${DBDIR}/gyeetadb/postgresql.conf ]; then
		echo -e "\nGyeeta's Postgres DB already initialized. No changes made to earlier configuration. Any changes in config such as Password will not be reflected...\n\n"
		exit 0
	fi

	if [ -z "$CFG_POSTGRES_PASSWORD" ]; then
		echo -e "\n\nERROR : Missing CFG_POSTGRES_PASSWORD environment variable for Postgres container. Please specify CFG_POSTGRES_PASSWORD and CFG_POSTGRES_PORT env first. Exiting...\n\n"
		exit 1
	fi	

	if [ -z "$CFG_POSTGRES_PORT" ]; then
		echo -e "\n\nERROR : Missing CFG_POSTGRES_PORT environment variable for Postgres container. Please specify CFG_POSTGRES_PASSWORD and CFG_POSTGRES_PORT env first. Exiting...\n\n"
		exit 1
	fi	

	./db_install.sh $DBDIR "$CFG_POSTGRES_PASSWORD" "$CFG_POSTGRES_PORT" "$CFG_POSTGRES_MAX_BUFFER_MB"
	
	exit $?
fi	

if [ ! -d $DBDIR ]; then
	echo -e "\n\nMissing Persistent Volume for Gyeeta's Postgres DB. Please mount the previously configured persistent volume at $DBDIR container mount point.\n\n"
	echo -e "If no previous init called, please run the Gyeeta Postgres container with command line args as : --initdb : Also set the CFG_POSTGRES_PASSWORD and CFG_POSTGRES_PORT env.\n\n"
	exit 1
fi

if [ ! -f ${DBDIR}/gyeetadb/gy_install.cfg 2> /dev/null ] || [ ! -f ${DBDIR}/gyeetadb/postgresql.conf 2> /dev/null ]; then

	if [ -n "$CFG_POSTGRES_PASSWORD" ] && [ -n "$CFG_POSTGRES_PORT" ]; then
		echo -e "\n\nNOTE : Postgres DB not yet initialized. Starting initialization now...\n\n"

		./db_install.sh $DBDIR "$CFG_POSTGRES_PASSWORD" "$CFG_POSTGRES_PORT" "$CFG_POSTGRES_MAX_BUFFER_MB"
		
		if [ $? -ne 0 ]; then
			exit $?
		fi	

		sleep 1
	else
		echo -e "Gyeeta Postgres container run without initialization. Please first initialize the DB with command line args as : --initdb : Also set the CFG_POSTGRES_PASSWORD and CFG_POSTGRES_PORT env.\n\n"
		exit 1
	fi

fi

./rundb.sh "$CMD" "$@" < /dev/null

if [ "$CMD" = "start" ] || [ "$CMD" = "restart" ]; then
	sleep 10

	if [ "x""`./rundb.sh printpids`" = "x" ]; then
		echo -e "\n\nERROR : postgresdb not running currently. Exiting...\n\n"
		exit 1
	fi	

	while `true`; do
		sleep 30

		./rundb.sh ps

		if [ "x""`./rundb.sh printpids`" = "x" ]; then
			echo -e "\n\nERROR : postgresdb not running currently. Exiting...\n\n"
			exit 1
		fi	
	done	

	# Wait indefinitely
	read /dev/null
fi

exit $?


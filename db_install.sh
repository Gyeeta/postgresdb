#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

if [ $# -lt 3 ]; then
	echo -e "\nUsage : $0 <DB Data directory> <DB 'postgres' user password> <Postgres Port to Listen on> <Optional DB Max Shared buffers in MB>\n\ne.g. $0 ./data dbPassword 10040\n\n"
	exit 1
fi	

if [ ! -f ./bin/pg_ctl ]; then
	echo -e "\n\nERROR : Please run this script from a proper install dir where bin/pg_ctl binary exists\n\n"
	exit 1
fi	

INSTALLDIR=$PWD
DBDIR=$1/gyeetadb/
PASS=$2
PORT=$3
OPTMB=$4
PASSFILE=$1/.___gy_pass_"$$".dat

if [ $PORT -gt 0 2> /dev/null ] && [ $PORT -lt 65535 ]; then
	:
else
	echo -e "\n\nERROR : Invalid Port specified for Postgres DB. Please specify a number between 1 and 65535.\n\n"
	exit 1
fi	

if [ ! -d $DBDIR ]; then
	mkdir -m 0775 -p $DBDIR $1/log

	if [ ! -d $DBDIR ]; then
		echo -e "\n\nERROR : Could not create DB Data dir $DBDIR \n\n"
		exit 1
	fi	
fi	

echo -n "$PASS" > $PASSFILE

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to create a temporary file in $PASSFILE : Please check if write permissions exist for $1 dir\n\n"
	exit 1
fi	

echo -e "\n\nNow creating new database in $DBDIR directory...\n\n"

./bin/initdb -D $DBDIR --locale=C --pwfile=$PASSFILE -A password --username=postgres

if [ $? -ne 0 ]; then
	rm -f $PASSFILE
	echo -e "\n\nERROR : Failed to create DB Database : Exiting\n\n"
	exit 1
fi

rm -f $PASSFILE

cp -f ./{postgresql.conf,pg_hba.conf} $DBDIR/

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to copy files to DB Data directory\n\n"
	exit 1
fi	

MEMMB=$( cat /proc/meminfo | grep MemTotal | awk -F: '{print $2}' | awk -Fk '{printf "%lu", $1/1024/5}' )

if [ -n "$OPTMB" ] && [ "$OPTMB" -lt $MEMMB 2> /dev/null ] && [ $OPTMB -gt 256 ]; then
	MEMMB=$OPTMB
fi	

printf "shared_buffers = ${MEMMB}MB\n" > $DBDIR/memory.conf

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to write to file in DB Data directory\n\n"
	exit 1
fi	

printf "port = $PORT\nmax_connections = 500\nlog_directory = '../log'\n" > $DBDIR/server.conf

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to write to file in DB Data directory\n\n"
	exit 1
fi	

echo -n $INSTALLDIR > $DBDIR/gy_install.cfg

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to create a file in DB Data dir\n\n"
	exit 1
fi

echo -n $DBDIR > ./cfg/dbdir.cfg

if [ $? -ne 0 ]; then
	echo -e "\n\nERROR : Failed to create a file in ./cfg dir : Please check if write permissions exist for that dir\n\n"
	exit 1
fi	

echo -e "\n\nInstalled Postgres DB with DB Dir $DBDIR successfully.\n\nTo connect to DB, username is : postgres\n\nTo start the DB please run : ./rundb.sh start\n\n"

exit 0


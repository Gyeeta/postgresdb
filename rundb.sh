#!/bin/bash

PATH=$PATH:/usr/bin:/sbin:/usr/sbin:.
export PATH

print_start()
{
	echo 
	echo ' Option <start> - To start the Gyeeta Postgres DB : 

 ./rundb.sh start
'
}

print_stop()
{
	echo 
	echo ' Option <stop> - To stop the Gyeeta Postgres DB components : 

 ./rundb.sh stop
'
}

print_restart()
{
	echo 
	echo ' Option <restart> - To restart the Gyeeta Postgres DB components : 

 ./rundb.sh restart
'
}


print_ps()
{
	echo
	echo ' Option <ps> -	To check the PID status of Gyeeta Postgres DB components

 ./rundb.sh ps
'
}

print_version()
{
	echo
	echo ' Option <version OR -v OR --version> - To get the Version information :

 ./rundb.sh version OR ./rundb.sh -v OR ./rundb.sh --version
'
}

print_complete_set()
{
echo -en "\n\n		Complete Set of Options : \n"

echo -en "	
	ps 	restart 	start		stop 	version 

	For Help on any option : please type 
	
	$0 help <Option>

	e.g. $0 help start

"

}

printusage()
{
echo -en "\n\n ------------------  Usage  -------------------\n"
print_start
print_stop
print_ps
print_version

print_complete_set

}

# ----------------  Help functions end for commands available ------------------------


GLOB_PRINT_PID=0

gy_pgrep()
{
	GLOB_PGREP_PID=""
	
	IS_FOUND=`./bin/pg_ctl -D $( cat ./cfg/dbdir.cfg ) status 2>&1 | grep "server is running" | awk -F"PID:" '{print $2}' | awk '{printf "%u", $1}'`

	if [ -n "$IS_FOUND" ]; then
		GLOB_PGREP_PID="$IS_FOUND"
		if [ $GLOB_PRINT_PID -eq 1 ]; then
			echo -n "$IS_FOUND"
		fi	
	fi
}


db_start_validate()
{
	gy_pgrep
	if [ -n "$GLOB_PGREP_PID" ]; then
		echo -en "\nNOTE : Gyeeta Postgres component(s) already running : PID(s) $GLOB_PGREP_PID\n\n"
		echo -en "Please run \"$0 restart\" if you need to restart the components...\n\n"

		exit 1
	fi
}

valid_install()
{
	if [ ! -f ./cfg/dbdir.cfg ] || [ ! -s ./cfg/dbdir.cfg ]; then 
		echo -en "\n\nERROR : Valid DB Data config not found in $PWD/cfg/dbdir.cfg : Please run db_install.sh script first to configure a proper install...\n\n"
		exit 1
	fi

	DBDIR=$( cat ./cfg/dbdir.cfg 2> /dev/null )

	if [ ! -d "$DBDIR" ]; then
		echo -en "\n\nERROR : Invalid DB Data specified in $PWD/cfg/dbdir.cfg : "$DBDIR" is not a directory : Please run db_install.sh script first to configure a proper install...\n\n"
		exit 1
	fi	

	if [ ! -f ${DBDIR}/gy_install.cfg 2> /dev/null ] || [ ! -f ${DBDIR}/postgresql.conf 2> /dev/null ]; then
		echo -en "\n\nERROR : DB Data dir in $PWD/cfg/dbdir.cfg : "$DBDIR" not yet initialized : Please run db_install.sh script first to configure a proper install...\n\n"
		exit 1
	fi	
}	

if [ $# -lt 1 ]; then
	printusage
	exit 1
fi

umask 0006

DNAME=`dirname $0 2> /dev/null`

if [ $? -eq 0 ]; then
	cd $DNAME
	CURRDIR=`pwd`
fi

if [ ! -f ./bin/pg_ctl ]; then 
	echo -en "\n\nERROR : Required binaries not found in $PWD/bin dir : Please run from a proper install...\n\n"
	exit 1
fi

export LD_LIBRARY_PATH=`pwd`/lib:$LD_LIBRARY_PATH

ARGV_ARRAY=("$@") 
ARGC_CNT=${#ARGV_ARRAY[@]} 
 

case "$1" in 

	help | -h | --help | \?)
		if [ $# -eq 1 ]; then	

			printusage
		else 
			shift

			for opt in $*;
			do	
				print_"$opt" 2> /dev/null
				if [ $? -ne 0 ]; then
					echo -en "\nERROR : Invalid Option $opt...\n\n"
					exit 1
				fi

				shift
			done
		fi

		;;

	start) 

		valid_install

		db_start_validate

		echo -en "\n\tStarting Gyeeta Postgres DB components...\n\n"

		shift 1

		./bin/pg_ctl -D $( cat ./cfg/dbdir.cfg ) start

		./rundb.sh ps

		gy_pgrep 
		if [ -z "$GLOB_PGREP_PID" ]; then
			echo -en "\n\tERROR : Gyeeta Postgres DB process not running. Please check log for ERRORs if no errors already printed...\n\n"
			exit 1
		fi

		if [ -n "$GY_FOREGROUND" ]; then
			trap 'echo "	Exiting now... Cleaning up..."; ./rundb.sh stop; exit 0' SIGINT SIGQUIT SIGTERM

			sleep 2

			gy_pgrep 
			if [ -z "$GLOB_PGREP_PID" ]; then
				echo -en "\n\tERROR : Gyeeta Postgres DB process not running. Please check log for ERRORs if no errors already printed...\n\n"
				exit 1
			fi

			echo -en "\nRunning Postgres DB in foreground as GY_FOREGROUND env set...\n"

			while true; do
				sleep 10

				gy_pgrep 
				if [ -z "$GLOB_PGREP_PID" ]; then
					echo -en "\n\tERROR : Gyeeta Postgres DB process not running. Please check log for ERRORs if no errors already printed...\n\n"
					exit 1
				fi
			done	

			exit 1
		fi

		exit 0

		;;

	
	stop)

		echo -en "\n\tStopping Gyeeta Postgres DB components : "

		gy_pgrep 
		[ -n "$GLOB_PGREP_PID" ] && ./bin/pg_ctl -D $( cat ./cfg/dbdir.cfg ) stop 2> /dev/null

		gy_pgrep 
		if [ -n "$GLOB_PGREP_PID" ]; then
			sleep 3
			gy_pgrep 
			
			if [ -n "$GLOB_PGREP_PID" ]; then
				echo -en "\n\t[ERROR]: Gyeeta Postgres process $GLOB_PGREP_PID not yet exited. Sending SIGKILL...\n\n"
				kill -KILL $GLOB_PGREP_PID
			fi	
		fi	

		echo -en "\n\n\tStopped all components successfully...\n\n"

		exit 0

		;;

	ps)

		echo -en "\n\tPID status of Gyeeta Postgres DB package components : "

		GLOB_PRINT_PID=1

		echo -en "\n\n\tGyeeta Postgres PID(s) : "
		gy_pgrep 
		
		if [ -n "$GLOB_PGREP_PID" ]; then
			echo -en "\n\n\n\tAll Components Running : Yes\n\n"
		else
			echo -en "\n\n\n\tAll Components Running : No\n\n"
		fi	

		exit 0

		;;

	printpids)
		shift

		GLOB_PRINT_PID=1
		
		gy_pgrep

		exit 0;
		;;

	restart)
	
		shift 

		valid_install

		./rundb.sh stop && sleep 1 && ./rundb.sh start "$@"

		exit $?
		;;

	-v | --version)

		POSTGRES_VERSION=`./bin/postgres --version | awk '{printf "%s.0", $NF}'`
		echo "postgres (PostgreSQL) $POSTGRES_VERSION"

		;;

	*)
		printusage
		exit 1

		;;
esac

exit 0


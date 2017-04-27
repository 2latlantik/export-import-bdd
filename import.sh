#!/bin/bash

# Paramètres 
USER='root'
PASSWORD=''
DATABASENAME='test'
EXTRACTFILE=""
# Directory
EXTRACTDIR='extract'
# Commands
UNCOMPRESSCMD="tar -xf"

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...] {start|stop|restart}" >&2
    echo
	echo "   -u, --user		User to connect to database"
    echo "   -p, --password		Password to connect to database"
    echo "   -f, --file		Archive for extraction"
	echo "   -db, --dataBase	Name of new	date base"
    echo
    exit 1
}

while true ; do
  case "$1" in
    --user | -u) 
		export USER="$2" ; 
		shift 2
	;;
    --password | -p) 
		export PASSWORD="$2" ; 
		shift 2 
	;;
	--file | -f) 
		export EXTRACTFILE="$2" ; 
		shift 2
	;;
	--dataBase | -db) 
		export DATABASENAME="$2" ; 
		shift 2 
	;;
	-h | --help)
         display_help  # Call your function
         exit 0
    ;;
    *) break ;;	
  esac
done


# Création du répertoire de travail
if [ -d "$EXTRACTDIR" ]; then
	rm -rf ${EXTRACTDIR}/*
else
	mkdir ${EXTRACTDIR}
fi
# Extraction des fichiers
${UNCOMPRESSCMD} save/${EXTRACTFILE} -C ${EXTRACTDIR}

# Parcours des fichiers
find ${EXTRACTDIR} -name '*.sql' | while read line; do 
	mysql -u ${USER} ${DATABASENAME} < $line
done

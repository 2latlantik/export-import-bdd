#!/bin/bash

# Paramètres 
USER='root'
PASSWORD=''
#EXTRACTFILE=""
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
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}

while true ; do
  case "$1" in
    --user | -u) 
		export USER="$2" ; 
		shift 
	;;
    --password | -p) 
		export PASSWORD ="$2" ; 
		shift  
	;;
	--file | -f) 
		export EXTRACTFILE="$2" ; 
		shift 
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
	mysql -u ${USER} test < $line
done

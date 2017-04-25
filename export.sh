#!/bin/bash

# Paramètres
USER='root'
PASSWORD=''
dataBaseDump='symfony'
# Répertoire de savegarde
DATADIR="save"
# Répertoire de travail
DATATMP=$DATADIR
# Nom des dumps
DATANAME="dump_$(date +%d.%m.%y@%Hh%M)" 
#Compression
COMPRESSIONCMD="tar -czf"
COMPRESSIONEXT=".tar.gz"
# Conservation des sauvegardes (en jours)
RETENTION=5
# Taille Table max et reste BDD 
tableTailleMax=20971520
baseTailleMin=36700160

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...] " >&2
    echo
	echo "   -u, --user		User to connect to database"
    echo "   -p, --password		Password to connect to database"
    echo "   -db, --dataBase		Date Base exported"
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
	--dataBase | -db) 
		export dataBaseDump="$2" ; 
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
mkdir -p ${DATATMP}/${DATANAME}

# Mémorisation des bases de données
requeteResults="$(mysql -u $USER -Bse 'SELECT table_name AS `TABLE`, (data_length + index_length) AS length_sum  FROM information_schema.TABLES WHERE table_schema = "symfony" ORDER BY length_sum DESC')"

# Formatage de la requête en tableau 
resultArray=()
for result in ${requeteResults[@]}
do
	fieldA=`echo ${result}| awk '{print $1}'`;
	resultArray+=(${fieldA})
	fieldB=`echo ${result}| awk '{print $2}'`;
	resultArray+=(${fieldB})
done

# Calcul de la taille de la base de données
resultArrayLength=${#resultArray[@]}
sizeBdd=0;
for((i=0; i<${resultArrayLength}; i+=2 ));
do
	sizeBdd=$((sizeBdd+${resultArray[$i+1]}))	
done

# Traitement de la structure des tables
mysqldump -u $USER --single-transaction --no-data $dataBaseDump > ${DATATMP}/${DATANAME}/aaa_structure.sql

# Découpage des tables 1 par 1
dataLeft=$sizeBdd
ignoredTablesString=''
for((i=0; i<${resultArrayLength}; i+=2 ));
do
	if [ $dataLeft -lt $baseTailleMin ]
	then
		break
	fi
	nomTable=${resultArray[$i]}
	tailleTable=${resultArray[$i+1]}
	
	echo "Table : ${resultArray[$i]} / Taille:${resultArray[$i+1]}"
	if [ $tailleTable -ge $tableTailleMax ]
	then
		nbDecoupage=$(($tailleTable/$tableTailleMax))
		createTable='-t'
		for((resteModulo=0 ; resteModulo<$nbDecoupage ; resteModulo++));
		do			
			mysqldump -u $USER $createTable --quick --add-locks --lock-tables --extended-insert --where "id%$nbDecoupage=$resteModulo" $dataBaseDump $nomTable  > ${DATATMP}/${DATANAME}/${nomTable}_${resteModulo}.sql
			createTable='-t'
		done
		ignoredTablesString+=" --ignore-table=${dataBaseDump}.${nomTable}"
		dataLeft=$((dataLeft-$tailleTable))
	fi	
done

# Si reste des data
if [ $dataLeft > 0 ]
then
	mysqldump -u $USER  -t --quick --add-locks --lock-tables --extended-insert $ignoredTablesString $dataBaseDump   > ${DATATMP}/${DATANAME}/${dataBaseDump}.sql
fi

# Compression
cd ${DATATMP}
${COMPRESSIONCMD} ${DATANAME}${COMPRESSIONEXT} ${DATANAME}
chmod 600 ${DATANAME}${COMPRESSIONEXT}
cd ..

# On le déplace dans le répertoire
if [ "$DATATMP" != "$DATADIR" ] ; then
    mv ${DATANAME}${COMPRESSIONEXT} ${DATADIR}
fi

# On supprime le répertoire temporaire 
rm -rf ${DATATMP}/${DATANAME}

# Suppression des anciens backups
find ${DATADIR} -name "*${COMPRESSIONEXT}" -mtime +${RETENTION} -print -exec rm {} \;

#!/bin/bash

if [[ $# -eq 0 ]]
then
	echo "Musisz podać jakiś argument.\n"
	exit 1
fi

if [[ $# -eq 3 ]]
then
	ciag=$3
else
	ciag=$2
fi


while getopts "r:ud:p:l" option
do
	case $option in
		r) 
			echo -e "Podaj znak, na jaki zamienić\n"
			read na_co_zamienic
			echo -e "${ciag//"$OPTARG"/"$na_co_zamienic"}"
			;;
		u) 
			echo -e "${ciag^^}"
			;;
		d) 
			echo -e "${ciag//"$OPTARG"}"
			;;
		p)
			echo -e "${ciag#*"$OPTARG"}"
			;;
		l) 
			echo -e "${#ciag}"
			;;	
		:) 
			echo -e "Opcja -$option wymaga argumentu."
			exit 1 ;;
		\?) 
			echo -e "Nieznana opcja: -$option"
			exit 1;;
	esac
done


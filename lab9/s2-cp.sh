#!/bin/bash

location=${PWD}

katalogi=$(find "$location" -mindepth 1 -type d)

if  [ "$katalogi" ]
then	
	for arg in "$@" 
	do
		if [[ -f "$arg" ]]
		then
			for katalog in $katalogi
			do
				cp "$arg" "$katalog/"
			done
		else
			echo -e "$arg - nie ma takiego pliku\n"
		fi
	done
fi

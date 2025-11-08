#!/bin/bash

if [[ "$#" -gt 0 ]]
then
	katalog=$1
else
	katalog=${PWD}
fi

pliki=$(find "$katalog" -maxdepth 1 -name "*.zip")

for plik in $pliki
do
	gdzie=$(basename "$plik" .zip)
	mkdir -p "$gdzie"
	unzip "$plik" -d "$gdzie"
done


#!/bin/bash

if [[ $# -eq 0 ]]
then
	echo -e "Brak parametrów\n"
	exit 1
fi

plik="$1"

if [[ ! -f "$plik" ]]
then
	echo -e "Podany plik nie istnieje\n"
	exit 1
fi

sed '1d' "$plik" | \
sed 's/^ *//;s/ *$//;s/ *; */;/g' | \
sed 's/\([^;]*\);\([^;]*\);.*/\2 \1/' | \
sort | \
cat -n | \
sed 's/^ *\([0-9]\+\)\t\(.*\)/\1. \2/' > 2


cat 2

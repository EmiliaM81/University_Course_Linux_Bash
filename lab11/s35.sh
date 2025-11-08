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

sed -E 's/\bfile\b/plik/g; s/("[^"]*)plik([^"]*")/\1file\2/g' "$plik" |
sed -E 's/([A-Za-z]+)_([A-Za-z]+)/\2_\1/' > 35 

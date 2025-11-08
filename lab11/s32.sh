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

sed -E '/\/\*+.*\*+\// {s/[\/\*]//g ; s/^/\/\//g}' "$plik" |  
sed -E '/\/\*+/,/\*+\// {s/[\*\/]//g ; s/.*\S/\/\/&/g}' > 32


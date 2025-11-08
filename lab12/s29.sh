#!/bin/bash

if [ "$#" -lt 2 ]; then
    exit 1
fi

plik=$1
shift
kolumny=($@)

if [ ! -f "$plik" ]; then
    echo "Plik $plik nie istnieje."
    exit 1
fi

awk_kolumny=""
for kolumna in "${kolumny[@]}"; do
    if [[ "$kolumna" =~ ^[0-9]+$ ]]; then
        awk_kolumny+="\$$kolumna\";"
    else
        echo "Kolumna $kolumna nie jest liczbą."
        exit 1
    fi
done

awk_kolumny=${awk_kolumny%;}

awk -F';' -v OFS=';' "{ print $awk_kolumny }" "$plik" 


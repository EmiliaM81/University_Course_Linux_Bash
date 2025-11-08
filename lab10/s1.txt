#!/bin/bash

echo -e "Podaj słowo: \n"

read slowo
echo -e "Podane słowo: $slowo\n"

echo -e "Podaj katalog, w którym będziesz wyszukiwać plików zawierających podane słowo: \n"

read katalog
echo -e "Podany katalog: $katalog\n"

licznik=0

if [[ ! "$katalog" ]]
then
	katalog=${PWD}
fi


shopt -s globstar

for file in "$katalog"/**
do
	if [[ -f "$file" ]]
	then
		ile_razy=$(egrep -o "\b$slowo\b" "$file" | wc -l)
		licznik=$((licznik + ile_razy))
	fi
done

echo -e "Liczba słow $licznik \n"

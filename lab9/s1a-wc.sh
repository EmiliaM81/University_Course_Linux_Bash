#!/bin/bash

echo -e "Podaj słowo: \n"

read slowo
echo  -e "Podane słowo: $slowo\n"

echo -e "Podaj katalog w ktorym będziesz wyszuiwać plików zawierających podane słowo: \n" 
read katalog
echo -e "Podany katalog: $katalog \n"

licznik=0

if [[ ! "$katalog"  ]] 
then
	katalog=${PWD}
fi

for plik in "$katalog"/* 
do
	if [[ -f "$plik" ]] 
	then
		ile_razy=$(egrep -o "\b$slowo\b" "$plik" | wc -l)
		licznik=$((licznik + ile_razy))
	fi
done

echo -e "Liczba słów: $licznik \n"   


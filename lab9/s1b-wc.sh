#!/bin/bash
echo -e "Podaj słowo: \n"

read slowo
echo  -e "Podane słowo: $slowo\n"

echo -e "Podaj katalog w ktorym będziesz wyszuiwać plików zawierających podane słowo: \n" 
read katalog
echo -e "Podany katalog: $katalog \n"


if [[ ! "$katalog"  ]] 
then
	katalog=${PWD}
fi

licznik=$(find "$katalog" -type f -exec egrep -o "\b$slowo\b" {} \; | wc -l)

echo -e "Liczba wystąpień: $licznik\n"

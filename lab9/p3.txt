#!/bin/bash -x

echo "Informacje o uruchomionym skrypcie"
echo "nazwa skryptu: $0"
echo -e "Liczba parametrów: $#\n"
echo -e "pierwszy parameter: $1\n"
echo -e "drugi parametr: $2\n"
shift 
echo -e "\n"
echo -e "Pierwszy parametr: $1 \n"
echo -e "Wszystkie parametry: $*\n"
echo -e "Wszystkie parametry: $@\n"

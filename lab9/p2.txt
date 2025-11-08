#!/bin/bash

echo -e "Podaj swoje imie:\n"
read imie
echo -e "Witaj $imie\n"

if [[ $( echo "$imie" | egrep "a$") ]]; then
	echo -e "Chyba jesteś dziewczyną!\n"
else
	echo -e "Chyba jesteś chłopakiem!\n"
fi


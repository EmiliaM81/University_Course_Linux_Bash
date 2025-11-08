#!/bin/bash
if [[  $1 =~ ^[0-9]+$ ]]
then 
	if [ $1 -gt 0 ]
	then 
		echo -e "Liczba $1 jest dodatnia\n"
	elif [ $1 -eq 0 ]
	then 
		echo -e "Liczba $1 jest zerem\n"
	else
		echo -e "Liczba $1 jest ujemna\n"
	fi
else
	echo -e "$1 to nie liczba!\n"
fi 

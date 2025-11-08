#!/bin/bash

if [[ "$#" -eq 0 || ! "$1" =~ [0-9]+ ]]
then
	N=5
else
	N=$1
fi

for((i=1;i<=N;i++))
do
	mkdir -p "Zadanie${i}"
	touch "Zadanie${i}/main.cpp"
	echo -e "//Emilia Wojtowicz Zadanie ${i}" > "Zadanie${i}/main.cpp"
        touch "Zadanie${i}/lab${i}.cpp"
        echo -e "//Emilia Wojtowicz Zadanie ${i}" > "Zadanie${i}/lab${i}.cpp"
        touch "Zadanie${i}/lab${i}.h"
        echo -e "//Emilia Wojtowicz Zadanie ${i}" > "Zadanie${i}/lab${i}.h"
done





#!/bin/bash

if [[ "$#" -gt 0 ]]
then
	arg=$1
else
	arg=${PWD}
fi

zwykle=0
katalogi=0
wykonywalne=0
inne=0

zmienne=$(find "$arg" -maxdepth 1)

for every in $zmienne
do
	if [[ -f $every ]]
	then
		zwykle=$((zwykle + 1))
	elif [[ -d $every ]]
	then
		katalogi=$((katalogi + 1))
	fi
	if [[ -x $every ]]
	then
		wykonywalne=$((wykonywalne + 1))
	else
		inne=$((inne + 1))
	fi
done 

echo -e "Ilość plików zwykłych: $zwykle\n"
echo -e "Ilość katalogów: $katalogi\n"
echo -e "Ilość wykonywalnych: $wykonywalne\n"
echo -e "Inne: $inne\n"

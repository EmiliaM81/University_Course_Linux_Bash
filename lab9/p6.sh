#!/bin/bash

echo -e "Przy użyciu \$*.:\n"

for arg in "$*"
do 
	echo -e "Argument: $arg\n"
done

echo -e  "\nPrzy użyciu \$@:\n"
for arg in "$@"
do
	echo -e "Argument: $arg"
done


while  [[ "$*" ]]
do
	echo -e "Argument: $*\n"
	shift
done

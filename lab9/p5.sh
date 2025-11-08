#!/bin/bash

echo -e "ls za pomocą pętli for: \n"

for item in $HOME/*
do 	
	if [[ -x $item ]]
	then
		echo -e "$item"
	fi
done

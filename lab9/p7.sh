#!/bin/bash

while pgrep pluma > /dev/null
do 
	echo -e "Edytor pluma jest uruchomiony\n"
	sleep 3
done
echo -e "Edytor pluma nie jest uruchomiony\n"

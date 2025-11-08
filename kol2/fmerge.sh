#!/bin/bash
if [[ "$#" -eq 0 ]]
then
	echo -e "nie podano argumentów\n"
	exit
fi
touch "merged.txt"
>"merged.txt"
for file in "$@"
do
	if [[ -f "$file" && -e "$file" ]]
	then
		echo -e "=========== ${file} =============" >> "merged.txt"
		cat "${file}" >> "merged.txt"
		echo -e "" >> "merged.txt"
	else
		echo -e "${file} to nie plik tekstowy\n"
	fi
done

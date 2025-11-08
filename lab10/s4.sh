#!/bin/bash

if [[ $# -eq 0 ]]
then
	echo -e "Brak argumentów.\n"
	exit 1
fi

for file in "$@"
do 
	echo -e "Podaj co chcesz zrobić.\n\n"
	echo -e "a - dodaj rozszerzenie ext\n"
	echo -e "b - usuń rozszerzenie\n"
	echo -e "e - zamień rozszerzenie na ext, dodaj rozszerzenie ext jeśli brak rozszerzenia\n"
	echo -e "c - zamień kolejność tego co jest przed myślnikiem z tym, co jest za myślnikiem\n"
	echo -e "d - obetnij nazwę pliku po pierwszym wystąpieniu znaku\n"
	echo -e "v - włącz tryb verbose"
	echo -e "h - podaj składnię polecenia i zakończ działanie skryptu\n\n"
	select opcja in "a" "b" "e" "c" "d" "v" "h"
	do
		case $opcja in 
		"a")
			mv "$file" "${file}.ext"
			break
			;;
		"b")	
			mv "$file" "${file%.*}"
			break
			;;
		"e")	
			nazwa="${file%.*}"
			mv "$file" "${nazwa}.ext"
			break
			;;
		"c")
			if [[ "$file" == *-* ]]
			then
				nazwa="${file%%-*}"
				reszta="${file#*-}"

				typ="${reszta##*.}"
				if [[ "$reszta" ==  *.* ]]
				then
					reszta="${reszta%.*}"
				fi

				if [[ -n "$typ" ]]
				then
					mv "$file" "${reszta}-${nazwa}.$typ"
				else
					mv "$file" "${reszta}-{$nazwa}"
				fi
			fi
			break
			;;
			
		"d")
			if [[ "$file" == *-* ]] 
			then
				nazwa="${file%%-*}"
				typ="${file##*.}"

				if [[ "$file" == *.* ]]
				then
					mv "$file" "${nazwa}.$typ"
				else
					mv "$file" "$nazwa"
				fi
			fi
			break
			;;
		"v")
			set -v
			break
			;;
		"h")
			echo -e "Koniec\n"
			exit 0
			;;
		"*")
			echo -e "Nieprawidłowa komenda\n"
			exit 1
			;;
		esac
	done
done
	

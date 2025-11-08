#!/bin/bash

echo -e "Podaj plik: \n"

read plik
while [[ ! -f "$plik" ]]
do
	echo -e "Taki plik nie istnieje. Spróboj jeszcze raz.\n"
	read plik
done

min_max()
{
	min=${liczby[0]}
	max=${liczby[0]}
	for liczba in "${liczby[@]}"
	do
		if (( liczba < min ))
		then
			min=$liczba
		fi
		if (( liczba > max )) then
			max=$liczba
		fi
	done
	echo "Najmniejsza liczba: $min"
	echo "Największa liczba: $max"
}

srednia()
{
	suma=0
	for liczba in "${liczby[@]}" 
	do
		suma=$((suma+liczba))
	done
	srednia=$(echo "scale=2; $suma / ${#liczby[@]}" | bc)
	echo "Średnia wartość: $srednia"
}

zwiekszenie_o_indeks()
{
	for i in "${!liczby[@]}"
	do
		liczby[$i]=$((liczby[$i] + i))
	done
	echo -e "Tablica po zwiekszeniu o wartości indeksów: ${liczby[@]}\n"
}

policz_wieksze()
{
	licznik=0
	echo -e "Podaj najmniejszą wartość\n"
	read min
	for liczba in "${liczby[@]}"
	do
		if ((liczba>=min))
		then
			licznik=$((licznik+1))
		fi
	done
	echo -e "Liczb większych od $min jest $licznik\n"
}

sortuj()
{
	liczby=($(echo "${liczby[@]}" | tr ' ' '\n' | sort -n))
	echo -e "Posortowane liczby: ${liczby[@]}\n"
}


liczby=($(egrep -o "\b[0-9]+\b" "$plik"))

if [[ ${#liczby[@]} -eq 0 ]];
then 
	echo "ten plik nie ma żadnych liczb."
	exit 1
fi

echo -e "Wybierz opcję: \n"
echo -e "a - wyświetl min i max\n"
echo -e "b - oblicz średnią\n"
echo -e "c - zwiększ o indeks\n"
echo -e "d - policz większe od podanej przez ciebie liczby\n"
echo -e "e - posortuj\n"
echo -e "f - zakończ\n"

select Y in a b c d e f
do
	case $Y in
		"a")
			min_max
			;;
		"b")
			srednia
			;;
		"c")
			zwiekszenie_o_indeks
			;;
		"d")
			policz_wieksze
			;;
		"e")
			sortuj
			;;
		"f")
			break
			;;
		"*")
			echo -e "Zła opcja.\n"
			exit 1
			;;
	esac
done

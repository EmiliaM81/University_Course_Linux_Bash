#!/usr/bin/awk -f

BEGIN {
FS =";";
OFS=" ";
srednia_calk=0;
l_stud=0;

print "IMIE","NAZWISKO","E-MAIL","LICZBA ZNALEZIONYCH WYNIKOW", "WYNIK SUMARYCZNY", "WYNIK SREDNI","WYNIK SREDNI Z POMINIECIEM NAJNIZSZEGO I NAJWYZSZEGO WYNIKU";
}

{
suma=0;
max=$4;
min=$4;


for (i=4;i<=NF;i++)
{
	if ($i>max)
	{
		max=$i
	}
	if ($i<min)
	{
		min=$i
	}
	suma+=$i
}

l_stud+=1;

print $1,$2,$3,NF-3, suma, suma/(NF-3), (suma-max-min)/(NF-5);

srednia_calk += suma/(NF-3);

}


END {
print "Srednia całkowita:", srednia_calk/l_stud;
}


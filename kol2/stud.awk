#!/usr/bin/awk -f

BEGIN {
OFS = "\t";
print "Imie", "Nazwisko", "Numer", "Liczba znalezionych wyników", "Wynik sumaryczny", "Wynik sredni";
}
{
suma=0;
l_wynikow=0;
for (i=4;i<=NF;i++)
{
	suma+=$i;
	l_wynikow+=1;

}
print $1,$2,$3,l_wynikow,suma,suma/l_wynikow;
}




#!/usr/bin/awk -f 

BEGIN {
    FS = ","
}

{
    email = $3
    imie_nazwisko = $1 " " $2
    klucz = email

    if (klucz in maile) {
        if (maile[klucz] != imie_nazwisko) {
            print $0, "Zawieral blad"
        } else {
            print $0
        }
    } else {
        maile[klucz] = imie_nazwisko
        print $0
    }
}

#!/usr/bin/awk -f

BEGIN {

    OFS = " ";
}

{
    if (NR % 4 == 1) {
        split($0, name, " ");
        imie = name[1];
        nazwisko = name[2];
    } else if (NR % 4 == 2) {
        tel = $0;
    } else if (NR % 4 == 3) {
        email = $0;
    } else if (NR % 4 == 0) {
        print nazwisko, imie, email, tel;
    }
}

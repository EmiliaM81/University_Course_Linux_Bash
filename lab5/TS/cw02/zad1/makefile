
clear:
	rm -f *.o *.a *.so program

static: 
	make clear
	gcc -Wall main.c -o program

cleartest:
	rm -rf wyniki.txt

test:
	make cleartest
	make static

	echo "Test" >> wyniki.txt
	echo "Ilość rekordów: 10 000 rozmiar 1b" >> wyniki.txt 
	#10000 elementów o rozmiarze 1bajt
	#kopiowanie
	./program generate dane.txt 10000 1
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 1 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 1 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 1 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 1 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 1bajt
	echo "Ilość rekordów: 1000 rozmiar 1b" >> wyniki.txt 
	
	#kopiowanie
	./program generate dane.txt 1000 1
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 1 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 1 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 1 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 1 lib) 2>> wyniki.txt
	
	#10000 elementów o rozmiarze 4bajt
	echo "Ilość rekordów: 10 000 rozmiar 4b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 10000 4
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 4 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 4 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 4 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 4 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 4bajt
	echo "Ilość rekordów: 1000 rozmiar 4b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 1000 4
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 4 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 4 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 4 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 4 lib) 2>> wyniki.txt


	#10000 elementów o rozmiarze 512bajt
	echo "Ilość rekordów: 10 000 rozmiar 512b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 10000 512
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 512 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 512 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 512 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 512 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 512bajt
	echo "Ilość rekordów: 1000 rozmiar 512b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 1000 512
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 512 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 512 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 512 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 512 lib) 2>> wyniki.txt


	#10000 elementów o rozmiarze 1024bajt
	echo "Ilość rekordów: 10 000 rozmiar 1024b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 10000 1024
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 1024 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 1024 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 1024 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 1024 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 1024bajt
	echo "Ilość rekordów: 1000 rozmiar 1024b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 1000 1024
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 1024 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 1024 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 1024 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 1024 lib) 2>> wyniki.txt
	

	#10000 elementów o rozmiarze 4096bajt
	echo "Ilość rekordów: 10 000 rozmiar 4096b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 10000 4096
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 4096 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 4096 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 4096 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 4096 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 4096bajt
	echo "Ilość rekordów: 1000 rozmiar 4096b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 1000 4096
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 4096 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 4096 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 4096 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 4096 lib) 2>> wyniki.txt


	#10000 elementów o rozmiarze 8192bajt
	echo "Ilość rekordów: 10 000 rozmiar 8192b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 10000 8192
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 10000 8192 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 8192 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 10000 8192 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 10000 8192 lib) 2>> wyniki.txt
	
	#1000 elementów o rozmiarze 8192bajt
	echo "Ilość rekordów: 1000 rozmiar 8192b" >> wyniki.txt 
	#kopiowanie
	./program generate dane.txt 1000 8192
	echo "Systemowe kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 1000 8192 sys) 2>> wyniki.txt
	echo "Biblioteczne kopiowanie" >> wyniki.txt && (time ./program copy dane.txt copy.txt 100 8192 lib) 2>> wyniki.txt
	#sortowanie
	echo "Systemowe sortowananie" >> wyniki.txt && (time ./program sort dane.txt 1000 8192 sys) 2>> wyniki.txt
	echo "Biblioteczne sortowanie" >> wyniki.txt && (time ./program sort copy.txt 1000 8192 lib) 2>> wyniki.txt


	
	make clear
	

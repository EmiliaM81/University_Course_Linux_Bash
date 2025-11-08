#!/bin/bash

# to jest komentarz

echo -e "katalog domowy uzytkownika $USER:\n${HOME}"
echo -e "\n"
echo -e "biezacy katalog:\n\a$(pwd)"
echo -e "\n nazwa hosta: $(hostname)\n"
echo -e "Aktualna godzina: $(date +%H-%M-%S)\n"

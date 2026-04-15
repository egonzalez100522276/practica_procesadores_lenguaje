#! /usr/bin/bash

bison trad3.y
gcc -o trad3 trad3.tab.c
bison back3.y
gcc -o back3 back3.tab.c
echo "Compilación terminada"
echo "Traduciendo a Lisp:"
./trad3 < prueba.c| ./back3 > prueba.fs
echo "Traducción a Lisp terminada"
echo "Compilación a GForth terminada"

echo "Ejecución del programa en GForth:"
gforth prueba.fs -e bye
echo "Fin del programa"
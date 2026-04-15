#! /usr/bin/bash

bison trad3.y
gcc -o trad3 trad3.tab.c
bison back3.y
gcc -o back3 back3.tab.c
./trad3 < prueba.c | ./back3 > prueba.fs
gforth prueba.fs -e bye
#include <stdio.h>

#define INC(x) x=x+1
#define DEC(x) x=x-1

fibonacci (int n) {
	int retorno;

	if (n < 2) {
		retorno = 1;
	} else {
		retorno = fibonacci (n-1) + fibonacci (n-2) ;
	}

	return retorno;
}

main ()
{
	int resultado;
	int i ;

        puts ("Sucesion de Fibonacci") ;

        for (i = 2 ; i < 50 ; INC(i)) {
		resultado = fibonacci (i) ;
                printf ("%d %s %d", i, " ", resultado) ;
                puts (" ") ;
        }
}

//@ (main) 


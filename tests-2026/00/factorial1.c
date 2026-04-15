#include <stdio.h>

int resultado ;
int n ;

main () 
{
    n = 7 ;
    resultado = 1 ;

    while (n > 1) {
        resultado = resultado * n ;
        n = n - 1 ;
    }
    printf("%d\n", resultado) ;
    
//    system ("pause") ;
}

//@ (main) 


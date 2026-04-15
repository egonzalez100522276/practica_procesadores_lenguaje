#include <stdio.h>

int primo ;
int n  ;
int m ;

int d ;
int i ;
int p ;

main ()
{
    i = 1 ; 
    n = 1 ; 
    m = 100 ;
    
    i = 2 ;
    while (i < m) {
        primo = 1 ;
        d = 2 ;
        while (d < i) {
            if (i % d == 0) {   // check for right precedence
                primo = 0 ;
            }
            d = d + 1 ;
        }

        if (primo != 0) {
            printf ("%d %s", i, " ") ;
        }
        i = i + 1 ;
    } 

//    system ("pause") ;
}

//@ (main)


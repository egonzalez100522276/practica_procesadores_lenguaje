#include <stdio.h>

#define INC(x) x=x+1
#define DEC(x) x=x-1

int primo ;
int n  ;
int m ;

main ()
{
    int d ;
    int i ;
    int p ;

    i = 1 ; 
    n = 1 ; 
    m = 100 ;
    
    for (i = 1 ; i <= m ; INC(i)) {  
        primo = 1 ;
        for (d = 2 ; d < i ; INC(d)) {
            if (i % d == 0) { // check precedences
                primo = 0 ;
            }
        }

        if (primo != 0) {
            printf ("%d %s", i, " ") ;
        }

    }
}

//@ (main)


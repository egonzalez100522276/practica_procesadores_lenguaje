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
        d = 2 ;
        primo = 1 ;
        while (primo == 1 && d<i) { // check precedences 
            p = i % d ;
            if (p == 0) {
                primo = 0 ;
            }
            d = d + 1 ;
        }

        if (primo == 1) {
            printf ("%d %s", i, " ") ;
        }
    }
}

//@ (main)



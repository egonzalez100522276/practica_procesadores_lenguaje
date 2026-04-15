#include <stdio.h>

cuadrado (int a) 
{
    int c ;

    c = a * a ;    

    return c ;
}

main ()
{
     int a ;
     int c ;
     
     a = 7 ;
     puts ("El cuadrado de ") ;
     printf ("%d", a) ;
     c = cuadrado (a) ;
     puts (" es ") ;
     printf ("%d\n", c) ;

     a = 12 ;
     printf ("%s %d %s %d ", "El cuadrado de ", a, " es: ", cuadrado (a)) ;
     puts (" ") ;

//   system("pause") ;
}

//@ (main)

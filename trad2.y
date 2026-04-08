/* ERNESTO GONZALEZ CEREZO, HECTOR FUERTES MUNOZ, 214
100522276@alumnos.uc3m.es, 100522401@alumnos.uc3m.es
*/

%{                          // SECCION 1 Declaraciones de C-Yacc

#include <stdio.h>
#include <ctype.h>            // declaraciones para tolower
#include <string.h>           // declaraciones para cadenas
#include <stdlib.h>           // declaraciones para exit ()

#define FF fflush(stdout);    // para forzar la impresion inmediata

int yylex () ;
int yyerror (char *mensaje) ;
char *my_malloc (int) ;
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

// Aumentamos considerablemente el tamaño del buffer temporal para 
// evitar desbordamientos de memoria al juntar bloques grandes de codigo
char temp [2048] ; 

// -- Novedades Punto 8: Gestion de Variables Locales --
char current_function[256] = "";     // Guarda el nombre de la funcion actual
char local_vars[100][256];           // Tabla simple de variables locales
int local_var_count = 0;             // Contador de variables locales

void add_local_var(char *name);      // Anade a la tabla local
int is_local_var(char *name);        // Comprueba si esta en la tabla
void clear_local_vars();             // Limpia la tabla al entrar a otra funcion
char* get_var_name(char *name);      // Devuelve "var" o "func_var"

// Abstract Syntax Tree (AST) Node Structure

typedef struct ASTnode t_node ;

struct ASTnode {
    char *op ;
    int type ;      // leaf, unary or binary nodes
    t_node *left ;
    t_node *right ;
} ;


// Definitions for explicit attributes

typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER 
    char *code ;   // - to pass IDENTIFIER names, and other translations 
    t_node *node ; // - for possible future use of AST
} t_attr ;

#define YYSTYPE t_attr

%}

// Definitions for explicit attributes

%token NUMBER        
%token IDENTIF       // Identificador=variable
%token INTEGER       // identifica el tipo entero
%token STRING
%token MAIN          // identifica el comienzo del proc. main
%token PUTS          
%token PRINTF
%token WHILE         // identifica el bucle main
%token IF
%token ELSE

%token GEQ
%token LEQ
%token EQ
%token NEQ
%token AND
%token OR

%right '='                    
%left OR                        // es la ultima operacion que se debe realizar
%left AND
%left EQ NEQ                 
%left '<' LEQ '>' GEQ
%left '+' '-'                 // menor orden de precedencia
%left '*' '/' '%'                // orden de precedencia intermedio
%right '!'                    
%right UNARY_SIGN              // mayor orden de precedencia

%%                            // Seccion 3 Gramatica - Semantico

axioma:     declaraciones_globales main           { sprintf(temp, "%s\n%s", $1.code, $2.code);
                                                    printf("%s\n", temp); }
            | main                       { printf("%s\n", $1.code); }
            ;

// Subregla util para inicializar el entorno local justo antes de leer el bloque de codigo
init_func:  /* vacio */                  { strcpy(current_function, "main"); clear_local_vars(); }
            ;

main:       MAIN '(' ')' '{' init_func codigo '}'   {sprintf(temp, "(defun main ()\n%s\n)", $6.code);
                                          $$.code = gen_code(temp); }
            | MAIN '(' ')' '{' init_func '}'        {$$.code = gen_code("(defun main ()\n)");}
            ;

// Cambiado a recursividad por la IZQUIERDA (codigo sentencia) para mayor estabilidad
codigo:     sentencia                { $$.code = $1.code; }
            | codigo sentencia       { sprintf(temp, "%s\n%s", $1.code, $2.code);
                                           $$.code = gen_code(temp); }
            ;

sentencia:  declaracion_local ';'                               { $$.code = $1.code ; }
            | asignacion_sentencia ';'                         { $$.code = $1.code ; }
            | PUTS '(' STRING ')' ';'                          {sprintf(temp, "(print \"%s\")", $3.code);
                                                            $$.code = gen_code(temp); }
            // Reparado PRINTF para que imprima la cadena y luego las variables
            | PRINTF '(' STRING ',' lista_printf ')' ';'       {sprintf(temp, "(princ \"%s\")\n%s", $3.code, $5.code);
                                                            $$.code = gen_code(temp);}

            | WHILE '(' expresion ')' '{' codigo '}'        {sprintf(temp, "(loop while %s do\n%s)", $3.code, $6.code);
                                                             $$.code = gen_code(temp);}     
            
            | IF '(' expresion ')' '{' codigo '}' {sprintf(temp, "(if %s (progn\n%s))", $3.code, $6.code);
                                                    $$.code = gen_code(temp);}
            | IF '(' expresion ')' '{' codigo '}' ELSE '{' codigo '}' {sprintf(temp, "(if %s \n(progn %s) \n(progn %s))", $3.code, $6.code, $10.code);
                                                                        $$.code = gen_code(temp);}
            ;

asignacion_sentencia: IDENTIF '=' expresion    { char *var_name = get_var_name($1.code);
                                                 sprintf(temp, "(setf %s %s)", var_name, $3.code);
                                                $$.code = gen_code(temp); };

// Recursividad por la izquierda
lista_printf: expresion                         {sprintf(temp, "(princ %s)", $1.code);
                                                $$.code = gen_code(temp);}
            | lista_printf ',' expresion        {sprintf(temp, "%s\n(princ %s)", $1.code, $3.code);
                                                $$.code = gen_code(temp);};
                                                
// Recursividad por la izquierda
declaraciones_globales:     declaracion_global ';'                              {$$.code = $1.code;}
                            | declaraciones_globales declaracion_global ';'     {sprintf(temp, "%s\n%s", $1.code, $2.code);
                                                                                 $$.code = gen_code(temp);}
                            ;

declaracion_global:  
                INTEGER r_dec_global               { $$.code = $2.code ; }
            ;

// Recursividad por la izquierda
r_dec_global:
                asignacion_global                   { $$.code = $1.code; }
                | r_dec_global ',' asignacion_global { sprintf(temp, "%s\n%s", $1.code, $3.code);
                                                        $$.code = gen_code(temp); }
                ;

asignacion_global: IDENTIF                  { sprintf(temp, "(setq %s 0)", $1.code); $$.code = gen_code(temp); } 
                    | IDENTIF '=' NUMBER    { sprintf(temp, "(setq %s %d)", $1.code, $3.value); $$.code = gen_code(temp); }
                    ; 


declaracion_local: INTEGER r_dec_local               { $$.code = $2.code ; }

// Recursividad por la izquierda
r_dec_local: asignacion_local                        { $$.code = $1.code; }
            | r_dec_local ',' asignacion_local       {
                                                    sprintf(temp, "%s\n%s", $1.code, $3.code);
                                                    $$.code = gen_code(temp);
                                                }
            ;

asignacion_local: IDENTIF                      { add_local_var($1.code);
                                                 sprintf(temp, "(setq %s_%s 0)", current_function, $1.code); 
                                                 $$.code = gen_code(temp); } 
            | IDENTIF '=' expresion      { add_local_var($1.code);
                                           sprintf(temp, "(setq %s_%s %s)", current_function, $1.code, $3.code); 
                                           $$.code = gen_code(temp); }
            ; 
            

expresion:    termino                    { $$ = $1 ; }
            | expresion '+' expresion    { sprintf (temp, "(+ %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }

            | expresion '-' expresion    { sprintf (temp, "(- %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }

            | expresion '*' expresion    { sprintf (temp, "(* %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }

            | expresion '/' expresion    { sprintf (temp, "(/ %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }

            | expresion '%' expresion    {sprintf(temp, "(mod %s %s)", $1.code, $3.code);
                                           $$.code = gen_code(temp);}

            | expresion EQ expresion     {sprintf(temp, "(= %s %s)", $1.code, $3.code);
                                           $$.code = gen_code(temp);}

            | expresion NEQ expresion    {sprintf(temp, "(/= %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion '<' expresion    {sprintf(temp, "(< %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion '>' expresion    {sprintf(temp, "(> %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion LEQ expresion    {sprintf(temp, "(<= %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion GEQ expresion    {sprintf(temp, "(>= %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion AND expresion    {sprintf(temp, "(and %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | expresion OR expresion     {sprintf(temp, "(or %s %s)", $1.code, $3.code);
                                          $$.code = gen_code(temp);}

            | '!' expresion             {sprintf(temp, "(not %s)", $2.code);
                                          $$.code = gen_code(temp);}
            ;

termino:        operando                           { $$ = $1 ; }          

            |   '+' operando %prec UNARY_SIGN      { sprintf (temp, "(+ %s)", $2.code) ;
                                                     $$.code = gen_code (temp) ; }  
            |   '-' operando %prec UNARY_SIGN      { sprintf (temp, "(- %s)", $2.code) ;
                                                     $$.code = gen_code (temp) ; }    
            ;

operando:       IDENTIF                  { char *var_name = get_var_name($1.code);
                                           sprintf (temp, "%s", var_name) ;
                                           $$.code = gen_code (temp) ; }
            |   NUMBER                   { sprintf (temp, "%d", $1.value) ;
                                           $$.code = gen_code (temp) ; }
            |   '(' expresion ')'        { $$ = $2 ; }
            ;


%%                            // SECCION 4    Codigo en C

int n_line = 1 ;

int yyerror (char *mensaje)
{
    fprintf (stderr, "%s en la linea %d\n", mensaje, n_line) ;
    printf ( "\n") ;    // bye
}

char *int_to_string (int n)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%d", n) ;

    return gen_code (ltemp) ;
}

char *char_to_string (char c)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%c", c) ;

    return gen_code (ltemp) ;
}

char *my_malloc (int nbytes)       // reserva n bytes de memoria dinamica
{
    char *p ;
    static long int nb = 0;        // sirven para contabilizar la memoria
    static int nv = 0 ;            // solicitada en total

    p = malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria para %d bytes mas\n", nbytes) ;
        fprintf (stderr, "Reservados %ld bytes en %d llamadas\n", nb, nv) ;
        exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}

// -- Novedades Punto 8: Implementacion de funciones de Tabla Local --

void add_local_var(char *name) {
    if (local_var_count < 100) {
        strcpy(local_vars[local_var_count++], name);
    }
}

int is_local_var(char *name) {
    for (int i = 0; i < local_var_count; i++) {
        if (strcmp(local_vars[i], name) == 0) {
            return 1;
        }
    }
    return 0;
}

void clear_local_vars() {
    local_var_count = 0;
}

// Genera dinamicamente el string correcto de la variable dependiento de su entorno
char* get_var_name(char *name) {
    if (is_local_var(name)) {
        char temp_name[512];
        sprintf(temp_name, "%s_%s", current_function, name);
        return gen_code(temp_name);
    }
    return name;
}


/***************************************************************************/
/********************** Seccion de Palabras Reservadas *********************/
/***************************************************************************/

typedef struct s_keyword { // para las palabras reservadas de C
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = { // define las palabras reservadas y los
    "main",        MAIN,           // y los token asociados
    "int",         INTEGER,
    "puts",        PUTS,
    "printf",      PRINTF,
    "while",       WHILE,
    ">=",          GEQ,
    "<=",          LEQ,
    "==",          EQ,
    "!=",          NEQ,
    "&&",          AND,
    "||",          OR,
    "if",          IF,
    "else",        ELSE,
    // añadir más palabras aquí 
    // (···)
    NULL,          0               // para marcar el fin de la tabla
} ;

t_keyword *search_keyword (char *symbol_name)
{                                  // Busca n_s en la tabla de pal. res.
                                   // y devuelve puntero a registro (simbolo)
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
        if (strcmp (sim [i].name, symbol_name) == 0) {
                                     // strcmp(a, b) devuelve == 0 si a==b
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}

 
/***************************************************************************/
/******************* Seccion del Analizador Lexicografico ******************/
/***************************************************************************/

char *gen_code (char *name)     // copia el argumento a un
{                                      // string en memoria dinamica
    char *p ;
    int l ;
    
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
    
    return p ;
}


int yylex ()
{
// NO MODIFICAR ESTA FUNCION SIN PERMISO
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;

        if (c == '#') { // Ignora las lineas que empiezan por #  (#define, #include)
            do {        //  OJO que puede funcionar mal si una linea contiene #
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') { // Si la linea contiene un / puede ser inicio de comentario
            cc = getchar () ;
            if (cc != '/') {   // Si el siguiente char es /  es un comentario, pero...
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;    // ...
                if (c == '@') { // Si es la secuencia //@  ==> transcribimos la linea
                    do {        // Se trata de codigo inline (Codigo embebido en C)
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n') ;
                } else {        // ==> comentario, ignorar la linea
                    while (c != '\n') {
                        c = getchar () ;
                    }
                }
            }
        } else if (c == '\\') c = getchar () ;
        
        if (c == '\n')
            n_line++ ;

    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && i < 255) ;
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }           // habria que leer hasta el siguiente " , pero, y si falta?
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
//         printf ("\nDEV: NUMBER %d\n", yylval.value) ;        // PARA DEPURAR
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL) {    // no es palabra reservada -> identificador antes vrariabre
//               printf ("\nDEV: IDENTIF %s\n", yylval.code) ;    // PARA DEPURAR
            return (IDENTIF) ;
        } else {
//               printf ("\nDEV: OTRO %s\n", yylval.code) ;       // PARA DEPURAR
            return (symbol->token) ;
        }
    }

    if (strchr (ops_expandibles, c) != NULL) { // busca c en ops_expandibles
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ; // aunque no se use
            return (symbol->token) ;
        }
    }

//    printf ("\nDEV: LITERAL %d #%c#\n", (int) c, c) ;      // PARA DEPURAR
    if (c == EOF || c == 255 || c == 26) {
//         printf ("tEOF ") ;                                // PARA DEPURAR
        return (0) ;
    }

    return c ;
}


int main ()
{
    yyparse () ;
}
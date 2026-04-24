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

// Aumentamos el tamaño del buffer temporal para 
// evitar desbordamientos de memoria al juntar bloques grandes de codigo
char temp [2048] ; 

// Gestion de Variables Locales --
typedef struct {
    char *name;
    char *translated;
} t_local_var;

t_local_var local_table[100];
int local_var_count = 0;
char current_function[256] = "";


void add_local_var(char *name);      // Anade a la tabla local
t_local_var *search_local_var(char *name);  // Busca en la tabla 
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
%token RETURN

%token GEQ
%token LEQ
%token EQ
%token NEQ
%token AND
%token OR
%token FOR
%token INC
%token DEC
%token SWITCH
%token CASE
%token DEFAULT
%token BREAK

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

axioma:     
            declaraciones_globales lista_funciones main {
                sprintf(temp, "%s\n%s\n%s", $1.code, $2.code, $3.code);
                printf("%s\n", temp);
            }
            | declaraciones_globales main { 
                sprintf(temp, "%s\n%s", $1.code, $2.code);
                printf("%s\n", temp); 
            }
            | lista_funciones main {
                sprintf(temp, "%s\n%s", $1.code, $2.code);
                printf("%s\n", temp);
            }
            | main { 
                printf("%s\n", $1.code); 
            }
            ;

// util para inicializar el entorno local antes de leer el bloque de codigo
init_func:  /* vacio */  { 
                strcpy(current_function, "main"); clear_local_vars(); 
            }
            ;

main:       MAIN '(' ')' '{' init_func codigo '}' {
                sprintf(temp, "(defun main ()\n%s\n)\n(main)", $6.code);
                $$.code = gen_code(temp); 
            }
            | MAIN '(' ')' '{' init_func '}' {
                $$.code = gen_code("(defun main ()\n)\n(main)");
            }
            ;

lista_funciones: funcion {
                    $$.code = $1.code;
                 }
                | lista_funciones funcion {
                    sprintf(temp, "%s\n%s", $1.code, $2.code);
                    $$.code = gen_code(temp);
                }
                ;

funcion:
        IDENTIF '(' ')' '{' {
            strcpy(current_function, $1.code);
            clear_local_vars();
        } cuerpo_funcion {
            sprintf(temp, "(defun %s ()\n%s\n)", $1.code, $6.code);
            $$.code = gen_code(temp);
        }
        | IDENTIF '(' {
            strcpy(current_function, $1.code);
            clear_local_vars();
        } parametros_funcion ')' '{' cuerpo_funcion {
            sprintf(temp, "(defun %s (%s)\n%s\n)", $1.code, $4.code, $7.code);
            $$.code = gen_code(temp);
        }
        ;

cuerpo_funcion:
        codigo '}' {
            $$.code = $1.code;
        }
        | '}' {
            $$.code = gen_code("");
        }
        ;

llamada_funcion:    IDENTIF '(' ')' {
                        sprintf(temp, "(%s)", $1.code);
                        $$.code = gen_code(temp);
                    }
                    | IDENTIF '(' lista_parametros_llamada ')' {
                        sprintf(temp, "(%s %s)", $1.code, $3.code);
                        $$.code = gen_code(temp);
                    }
                    ;

acceso_vector:      IDENTIF '[' expresion ']' {
                        char *var_name = get_var_name($1.code);
                        sprintf(temp, "(aref %s %s)", var_name, $3.code);
                        $$.code = gen_code(temp);
                    }
                ;

parametros_funcion: parametro_funcion {
                        $$.code = $1.code;
                    }
                    | parametros_funcion ',' parametro_funcion {
                        sprintf(temp, "%s %s", $1.code, $3.code);
                        $$.code = gen_code(temp);
                    }
                    ;

parametro_funcion:  INTEGER IDENTIF {
                        add_local_var($2.code);
                        sprintf(temp, "%s_%s", current_function, $2.code);
                        $$.code = gen_code(temp);
                    }
                    ;

lista_parametros_llamada: expresion {
                            $$.code = $1.code;
                         }
                        | lista_parametros_llamada ',' expresion {
                                sprintf(temp, "%s %s", $1.code, $3.code);
                                $$.code = gen_code(temp);
                        }
                        ;
codigo:     sentencia { 
                $$.code = $1.code; 
            }
            | codigo sentencia  { 
                sprintf(temp, "%s\n%s", $1.code, $2.code);
                $$.code = gen_code(temp); 
            }
            ;

sentencia:  declaracion_local ';' {
                $$.code = $1.code ;
            }
            | asignacion_sentencia ';' {
                $$.code = $1.code ;
            }
            | PUTS '(' STRING ')' ';' {
                sprintf(temp, "(print \"%s\")", $3.code);
                $$.code = gen_code(temp); 
            }
            | PRINTF '(' STRING ',' lista_printf ')' ';' {
                sprintf(temp, "%s", $5.code);
                $$.code = gen_code(temp);
            }
            | WHILE '(' expresion ')' '{' codigo '}' {
                sprintf(temp, "(loop while %s do\n%s)", $3.code, $6.code);
                $$.code = gen_code(temp);
            }     
            | IF '(' expresion ')' '{' codigo '}' {
                sprintf(temp, "(if %s (progn\n%s))", $3.code, $6.code);
                $$.code = gen_code(temp);
            }
            | IF '(' expresion ')' '{' codigo '}' ELSE '{' codigo '}' {
                sprintf(temp, "(if %s \n(progn %s) \n(progn %s))", $3.code, $6.code, $10.code);
                $$.code = gen_code(temp);
            }
            | FOR '(' inicializacion_for ';' expresion ';' inc_dec ')' '{' codigo '}' { 
                sprintf(temp, "%s\n(loop while %s do\n%s\n%s)", $3.code, $5.code, $9.code, $7.code);
                $$.code = gen_code(temp);
            }
            | SWITCH '(' expresion ')' '{' lista_cases '}' {
                sprintf(temp, "(case %s\n%s)", $3.code, $6.code);
                $$.code = gen_code(temp);
            }
            | llamada_funcion ';' {
                $$.code = $1.code;
            }
            | RETURN expresion ';' {
                sprintf(temp, "(return-from %s %s)", current_function, $2.code);
                $$.code = gen_code(temp);
            }
            ;

asignacion_sentencia: IDENTIF '=' expresion    { 
                        char *var_name = get_var_name($1.code);
                        sprintf(temp, "(setf %s %s)", var_name, $3.code);
                        $$.code = gen_code(temp); 
                    }
                    | acceso_vector '=' expresion {
                        sprintf(temp, "(setf %s %s)", $1.code, $3.code);
                        $$.code = gen_code(temp);
                    }
                    ;

lista_printf: expresion {
                sprintf(temp, "(princ %s)", $1.code);
                $$.code = gen_code(temp);
            }
            | lista_printf ',' expresion {
                sprintf(temp, "%s\n(princ %s)", $1.code, $3.code);
                $$.code = gen_code(temp); 
            };
                                                
declaraciones_globales:     declaracion_global ';' {
                                $$.code = $1.code;
                            }
                            | declaraciones_globales declaracion_global ';' {
                                sprintf(temp, "%s\n%s", $1.code, $2.code);
                                $$.code = gen_code(temp);
                            }
                            ;

declaracion_global:  
                INTEGER r_dec_global {
                    $$.code = $2.code ;
                }
            ;

r_dec_global:
                asignacion_global {
                    $$.code = $1.code;
                }
                | r_dec_global ',' asignacion_global {
                    sprintf(temp, "%s\n%s", $1.code, $3.code);
                    $$.code = gen_code(temp);
                }
                ;

asignacion_global:  IDENTIF { 
                        sprintf(temp, "(setq %s 0)", $1.code); $$.code = gen_code(temp);
                    } 
                    | IDENTIF '=' NUMBER {
                        sprintf(temp, "(setq %s %d)", $1.code, $3.value); $$.code = gen_code(temp);
                    }
                    | IDENTIF '[' NUMBER ']' {
                        sprintf(temp, "(setq %s (make-array %d))", $1.code, $3.value);
                        $$.code = gen_code(temp);
                    }
                    ; 


declaracion_local: INTEGER r_dec_local {
                    $$.code = $2.code ;
                    }
                ;

r_dec_local: asignacion_local {
                $$.code = $1.code;
            }
            | r_dec_local ',' asignacion_local {
                sprintf(temp, "%s\n%s", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            ;

asignacion_local: IDENTIF {
                    add_local_var($1.code);
                    sprintf(temp, "(setq %s_%s 0)", current_function, $1.code); 
                    $$.code = gen_code(temp); 
                } 
                | IDENTIF '=' expresion { 
                    add_local_var($1.code);
                    sprintf(temp, "(setq %s_%s %s)", current_function, $1.code, $3.code); 
                    $$.code = gen_code(temp);
                }
                | IDENTIF '[' NUMBER ']' {
                    add_local_var($1.code);
                    sprintf(temp, "(setq %s_%s (make-array %d))", current_function, $1.code, $3.value);
                    $$.code = gen_code(temp);
                }
            ; 
            
inc_dec:    INC '(' IDENTIF ')' { 
                char *var_name = get_var_name($3.code);
                sprintf(temp, "(setf %s (+ %s 1))", var_name, var_name);
                $$.code = gen_code(temp);
            }
            | DEC '(' IDENTIF ')' { 
                char *var_name = get_var_name($3.code);
                sprintf(temp, "(setf %s (- %s 1))", var_name, var_name);
                $$.code = gen_code(temp);
            }
    ;


inicializacion_for: IDENTIF '=' expresion { 
                        char *var_name = get_var_name($1.code);
                        sprintf(temp, "(setf %s %s)", var_name, $3.code);
                        $$.code = gen_code(temp);
                    }
    ;

lista_cases: case_bloque {
                $$.code = $1.code;
            }
            | lista_cases case_bloque {
                sprintf(temp, "%s\n%s", $1.code, $2.code);
                $$.code = gen_code(temp);
            }
          ;

case_bloque: CASE NUMBER ':' codigo BREAK ';' {
                sprintf(temp, "(%d (progn\n%s))", $2.value, $4.code);
                $$.code = gen_code(temp);
            }
           | DEFAULT ':' codigo BREAK ';' {
                sprintf(temp, "(otherwise (progn\n%s))", $3.code);
                $$.code = gen_code(temp);
            }
           ;
expresion:    termino { 
                $$ = $1 ;
            }
            | expresion '+' expresion { 
                sprintf (temp, "(+ %s %s)", $1.code, $3.code) ;
                $$.code = gen_code (temp) ;
            }
            | expresion '-' expresion { 
                sprintf (temp, "(- %s %s)", $1.code, $3.code) ;
                $$.code = gen_code (temp) ;
            }
            | expresion '*' expresion { 
                sprintf (temp, "(* %s %s)", $1.code, $3.code) ;
                $$.code = gen_code (temp);
            }
            | expresion '/' expresion { 
                sprintf (temp, "(/ %s %s)", $1.code, $3.code) ;
                $$.code = gen_code (temp) ;
            }
            | expresion '%' expresion {
                sprintf(temp, "(mod %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion EQ expresion {
                sprintf(temp, "(= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion NEQ expresion {
                sprintf(temp, "(/= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion '<' expresion {
                sprintf(temp, "(< %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion '>' expresion {
                sprintf(temp, "(> %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion LEQ expresion {
                sprintf(temp, "(<= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion GEQ expresion {
                sprintf(temp, "(>= %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion AND expresion {
                sprintf(temp, "(and %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | expresion OR expresion {
                sprintf(temp, "(or %s %s)", $1.code, $3.code);
                $$.code = gen_code(temp);
            }
            | '!' expresion {
                sprintf(temp, "(not %s)", $2.code);
                $$.code = gen_code(temp);
            }
            ;

termino:    operando { 
                $$ = $1 ;
            }          
            |   '+' operando %prec UNARY_SIGN {
                $$ = $2;
            }  
            |   '-' operando %prec UNARY_SIGN {
                sprintf (temp, "(- %s)", $2.code) ;
                $$.code = gen_code (temp) ;
            }    
            ;

operando:       IDENTIF {
                    char *var_name = get_var_name($1.code);
                    sprintf (temp, "%s", var_name) ;
                    $$.code = gen_code (temp) ;
                }
                |   NUMBER { sprintf (temp, "%d", $1.value) ;
                    $$.code = gen_code (temp) ;
                }
                |   '(' expresion ')' { 
                        $$ = $2 ;
                }
                |   llamada_funcion {
                        $$ = $1;
                }
                | acceso_vector {
                    $$ = $1;
                }
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

void add_local_var(char *name)
{
    t_local_var *var;

    var = search_local_var(name);
    if (var != NULL) {
        return;
    }

    if (local_var_count < 100) {
        local_table[local_var_count].name = gen_code(name);

        sprintf(temp, "%s_%s", current_function, name);
        local_table[local_var_count].translated = gen_code(temp);

        local_var_count++;
    }
}

t_local_var *search_local_var(char *name)
{
    int i;

    for (i = 0; i < local_var_count; i++) {
        if (strcmp(local_table[i].name, name) == 0) {
            return &(local_table[i]);
        }
    }

    return NULL;
}

int is_local_var(char *name)
{
    return search_local_var(name) != NULL;
}


void clear_local_vars() {
    local_var_count = 0;
}

// Genera dinamicamente el string correcto de la variable dependiento de su entorno
char* get_var_name(char *name)
{
    t_local_var *var;

    var = search_local_var(name);
    if (var != NULL) {
        return var->translated;
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
    "for",         FOR,
    "inc",         INC,
    "dec",         DEC,
    "switch",       SWITCH,
    "case",        CASE,
    "default",     DEFAULT,
    "break",       BREAK,
    "return",      RETURN,

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
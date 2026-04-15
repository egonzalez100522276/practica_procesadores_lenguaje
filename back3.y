%{                          // SECTION 1 Declarations for C-Bison
#include <stdio.h>
#include <ctype.h>            // tolower()
#include <string.h>           // strcmp() 
#include <stdlib.h>           // exit()

#define FF fflush(stdout);    // to force immediate printing 

int yylex () ;
void yyerror (char *) ;
char *my_malloc (int) ;

// Not needed using Direct Translation:
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

char temp [2048] ;
char global_vars [8192] = "" ;


// Definitions for explicit attributes

typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER 
    char *code ;   // - to pass IDENTIFIER names, and other translations 
} t_attr ;

#define YYSTYPE t_attr     // stack of PDA has type t_attr

%}

// Definitions for explicit attributes

%token NUMBER        
%token IDENTIF       // Identifier=variable
%token STRING        // token for string type
%token MAIN          // token for keyword main // main is not predefined in Lisp but we will use it as a keyword0+
%token WHILE         // token for keyword while
%token LOOP
%token DO
%token DEFUN     
%token PRINT  
%token PRINC
%token AND
%token IF 
%token PROGN
%token SETQ
%token SETF
%token MOD
%token OR
%token NOT
%token GEQ
%token LEQ
%token NEQ


// %prec section not needed in LISP


%%                            // Section 3 Grammar - Semantic Actions
axiom:        exprSeq                           { printf("%s%s\n", global_vars, $1.code); }      // A Lisp program contains a sequence of at least one expression
            ;


exprSeq:      expression1                       { $$.code = $1.code; }      // level 1 expressions must exclude specific level 2 expressions. ToDo in the Future
                 r_exprSeq                      { if ($3.code) { sprintf(temp, "%s\n%s", $1.code, $3.code); $$.code = gen_code(temp); } }
            ;


r_exprSeq:    exprSeq                           { $$.code = $1.code; }
            |  /* lambda */                     { $$.code = gen_code(""); }
            ;


expression1:  expression                        { $$.code = $1.code; }  // Lisp can evaluate arithmetical (and similar) expressions in REPL mode
                                                       // REPL Mode should print out the evaluated expressions ==> Future TODO for the Forth translation

            | '(' SETQ IDENTIF number ')'       { 
                                                  char var_decl[256];
                                                  sprintf(var_decl, "VARIABLE %s\n", $3.code);
                                                  if (strstr(global_vars, var_decl) == NULL) strcat(global_vars, var_decl);
                                                  sprintf(temp, " %d %s ! ", $4.value, $3.code); 
                                                  $$.code = gen_code(temp);
                                                }  // This is the declaration of a variable which in Forth has to be of global scope
                                                                                                      
            | '(' SETF IDENTIF expression ')'   { sprintf(temp, " %s %s ! ", $4.code, $3.code); $$.code = gen_code(temp); }    // Using a variable as receiver requires adding the store operator (!) in Forth 

            | '(' PRINT STRING ')'              { sprintf(temp, " .\" %s\" CR ", $3.code); $$.code = gen_code(temp); }

            | '(' PRINC expression ')'          { sprintf(temp, " %s . ", $3.code); $$.code = gen_code(temp); }
            | '(' PRINC STRING ')'              { sprintf(temp, " .\" %s\" ", $3.code); $$.code = gen_code(temp); }    // Princ should be able to print both expreesions and strings
           
            | '(' PROGN exprSeq ')'             { $$.code = $3.code; }

            | '(' MAIN ')'                      { $$.code = gen_code(" main "); } // call to the main function 

            | '(' DEFUN MAIN                    
                '(' ')' exprSeq ')'             { sprintf(temp, ": main \n%s\n; ", $6.code); $$.code = gen_code(temp); }

            | '(' LOOP WHILE                    
                 expression                     
                 DO exprSeq ')'                 { sprintf(temp, " BEGIN %s WHILE %s REPEAT ", $4.code, $6.code); $$.code = gen_code(temp); }

            | '(' ifHead  expression1 ')'       { sprintf(temp, " %s %s THEN ", $2.code, $3.code); $$.code = gen_code(temp); }     // If Expression then Expression1

            | '(' ifHead  expression1           
                 expression1 ')'                { sprintf(temp, " %s %s ELSE %s THEN ", $2.code, $3.code, $4.code); $$.code = gen_code(temp); }    
            ;


ifHead:       IF expression                     { sprintf(temp, " %s IF ", $2.code); $$.code = gen_code(temp); }        
            ;


expression:   operand                                   { $$.code = $1.code; }                // Common expressions combine arithmetic, relational and boolean expressions, including base operands.

            | '(' '-' expression expression ')'         { sprintf(temp, " %s %s - ", $3.code, $4.code); $$.code = gen_code(temp); }      // binary minus operator 

            | '(' '+' expression expression ')'         { sprintf(temp, " %s %s + ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' '*' expression expression ')'         { sprintf(temp, " %s %s * ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' '/' expression expression ')'         { sprintf(temp, " %s %s / ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' MOD expression expression ')'         { sprintf(temp, " %s %s MOD ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' AND expression expression ')'         { sprintf(temp, " %s %s AND ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' OR expression expression ')'          { sprintf(temp, " %s %s OR ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' '>' expression expression ')'         { sprintf(temp, " %s %s > ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' '<' expression expression ')'         { sprintf(temp, " %s %s < ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' GEQ expression expression ')'         { sprintf(temp, " %s %s >= ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' LEQ expression expression ')'         { sprintf(temp, " %s %s <= ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' NEQ expression expression ')'         { sprintf(temp, " %s %s <> ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' '=' expression expression ')'         { sprintf(temp, " %s %s = ", $3.code, $4.code); $$.code = gen_code(temp); }
            | '(' NOT expression ')'                    { sprintf(temp, " %s 0= ", $3.code); $$.code = gen_code(temp); }

            | '(' '-' expression ')'                    { sprintf(temp, " %s negate ", $3.code); $$.code = gen_code(temp); } // Unary minus operator in Lisp
            ;


operand:      IDENTIF                            { sprintf(temp, " %s @ ", $1.code); $$.code = gen_code(temp); } // To use a variable as an operand requires adding the fetch operator (@)
            | number                             { $$.code = int_to_string($1.value); }
            ;


number:       NUMBER                             { $$.value = $1.value ; }  // number is an auxiliary Non Terminal to be used in the setq initialization
            ;


%%                            // SECTION 4    Code in C

int n_line = 1 ;

void yyerror (char *message)
{
    fprintf (stderr, "%s in line %d\n", message, n_line) ;
    printf ( "\n") ;
}

char *int_to_string (int n)
{
    char temp [1024] ;

    sprintf (temp, "%d", n) ;

    return gen_code (temp) ;
}

char *char_to_string (char c)
{
    char temp [1024] ;

    sprintf (temp, "%c", c) ;

    return gen_code (temp) ;
}

char *gen_code (char *name)   // copy the argument to an  
{                             // string in dynamic memory  
    char *p ;
    int l ;
	
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
	
    return p ;
}

char *my_malloc (int nbytes)     // reserve n bytes of dynamic memory 
{
    char *p ;
    static long int nb = 0 ;     // used to count the memory  
    static int nv = 0 ;          // required in total 

    p = malloc (nbytes) ;
    if (p == NULL) {
      fprintf (stderr, "No memory left for additional %d bytes\n", nbytes) ;
      fprintf (stderr, "%ld bytes reserved in %d calls \n", nb, nv) ;  
      exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}



/***************************************************************************/
/***************************** Keyword Section *****************************/
/***************************************************************************/

typedef struct s_keyword { // for the reserved words of C  
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = {     // define the keywords 
    "main",        MAIN,      // and their associated token  
    "defun",       DEFUN,
    "print",       PRINT,
    "princ",       PRINC,
    "loop",        LOOP,
    "while",       WHILE,
    "do",          DO,
    "and",         AND,
    "if",          IF,
    "progn",       PROGN,
    "setq",        SETQ,
    "setf",        SETF,
    "mod",         MOD,
    "or",          OR,
    "not",         NOT,
    "/=",          NEQ,
    "<=",          LEQ,
    ">=",          GEQ,
    NULL,          0          // 0 to mark the end of the table
} ;

t_keyword *search_keyword (char *symbol_name)
{                       // Search symbol names in the keyword table
                        // and return a pointer to token register
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
	    if (strcmp (sim [i].name, symbol_name) == 0) {
                                   // strcmp(a, b) returns == 0 if a==b  
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}

 
/***************************************************************************/
/******************** Section for the Lexical Analyzer  ********************/
/***************************************************************************/

int yylex ()
{
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char expandable_ops [] =  "!<>=|%&/-*+" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do { 
        c = getchar () ; 
        if (c == '#') { // Ignore the lines starting with # (#define, #include) 
            do { // WARNING that it may malfunction if a line contains # 
                c = getchar () ; 
            } while (c != '\n') ; 
        } 
        if (c == '/') { // character / can be the beginning of a comment. 
            cc = getchar () ; 
            if (cc != '/') { // If the following char is / is a comment, but.... 
                ungetc (cc, stdin) ; 
            } else { 
                c = getchar () ; // ... 
                if (c == '@') { // Lines starting with //@ are transcribed
                    do { // This is inline code (embedded code in C).
                        c = getchar () ; 
                        putchar (c) ; 
                    } while (c != '\n' && c != EOF) ;
                    if (c == EOF) {
                        ungetc (c, stdin) ;
                    } 
                } else { // ==> comment, ignore the line 
                    while (c != '\n') { 
                        c = getchar () ; 
                    } 
                } 
            } 
        } 
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
            printf ("WARNING: string with more than 255 characters in line %d\n", n_line) ; 
        } // we should read until the next “, but, what if it is  missing? 
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
//         printf ("\nDEV: NUMBER %d\n", yylval.value) ;       
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
        temp_str [i++] = tolower (c) ; // ALL TO SMALL LETTERS
        c = getchar () ; 
    } 
    temp_str [i] = '\0' ; // End of string  
    ungetc (c, stdin) ; // return excess char  

    yylval.code = gen_code (temp_str) ; 
    symbol = search_keyword (yylval.code) ;
    if (symbol == NULL) { // is not reserved word -> iderntifrier  
//               printf ("\nDEV: IDENTIF %s\n", yylval.code) ;    // PARA DEPURAR
            return (IDENTIF) ;
        } else {
//               printf ("\nDEV: OTRO %s\n", yylval.code) ;       // PARA DEPURAR
            return (symbol->token) ;
        }
    }

    if (strchr (expandable_ops, c) != NULL) { // // look for c in expandable_ops
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ; // although it is not used
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

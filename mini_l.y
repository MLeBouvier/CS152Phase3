%{
 #include <stdio.h>
 #include <stdlib.h>
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 int tempCount = 0;
 FILE * yyin;
%}

%union{
  double dval;
  int ival;
  char* str;
}

%error-verbose
%start program
%token MULT DIV PLUS MINUS MOD EQUAL L_PAREN R_PAREN END
%token PROGRAM BEGIN_PROGRAM END_PROGRAM ELSEIF FUNCTION BEGIN_PARAMS END_PARAMS
%token BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY
%token OF IF THEN ENDIF ELSE WHILE DO FOREACH IN BEGINLOOP ENDLOOP CONTINUE
%token READ WRITE AND OR NOT TRUE FALSE RETURN
%token EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_SQUARE_BRACKET R_SQUARE_BRACKET
%token ASSIGN 
%token <dval> NUMBER
%token <str> IDENTIFIER
%type <str> ident
%left PLUS MINUS
%left MULT DIV
%nonassoc NOT
%nonassoc UMINUS


%% 
program       :   functions 
              ;
        
functions    :    
              |   function functions 
              ;

function      :  FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS
                  BEGIN_BODY statements END_BODY 
              ;

declarations :    
              |   declaration SEMICOLON declarations 
              ;
        
declaration  :		idents COLON INTEGER 
              |   idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
			        ;
                       
statements   :   
              |  statement SEMICOLON statements 
              ;
                       
statement    :    var ASSIGN expression 
              |   IF bool-exp THEN statement SEMICOLON statements ENDIF 
              |   IF bool-exp THEN statement SEMICOLON statements ELSE statements ENDIF                
              |   WHILE bool-exp BEGINLOOP statement SEMICOLON statements ENDLOOP                
              |   DO BEGINLOOP statement SEMICOLON statements ENDLOOP WHILE bool-exp                
              |   READ vars 
              |   WRITE vars 
              |   CONTINUE 
              |   RETURN expression 
              ;
              
vars         :    var 
              |   vars COMMA var 
              ;
      
var          :    ident  
              |   ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET
              ;

bool-exp      :   relation-and-exp 
              |    bool-exp OR relation-and-exp  
              ;

relation-and-exp :  relation-exp 
                  |  relation-and-exp AND relation-exp 
                  ;

relation-exp  :  NOT relation-exp %prec NOT 
              |  expression comp expression  
              |  TRUE  
              |  FALSE  
              |  L_PAREN bool-exp R_PAREN 
              ;

comp         :   EQ  
              |  NEQ  
              |  LT  
              |  GT  
              |  LTE  
              |  GTE  
              ;
             
expressions   :  expression 
              |  expression COMMA expressions  
              ;        
              
expression   :    mult-exp 
              |   expression PLUS mult-exp 
              |   expression MINUS mult-exp 
              ;
              
mult-exp     :    term 
              |   mult-exp MULT term 
              |   mult-exp DIV term 
              |   mult-exp MOD term 
              ;

term         :    MINUS term %prec UMINUS 
              |   NUMBER 
              |   var 
              |   L_PAREN expression R_PAREN 
              |   ident L_PAREN expressions R_PAREN 
              |   ident L_PAREN R_PAREN 
              ;
              
idents       :    ident 
              |   ident COMMA idents 
              ;
              
ident        :    IDENTIFIER    { $$ = $1, printf(". %s\n", $1), printf(".__temp__%d\n",tempCount), tempCount = tempCount + 1;}
              ;
%%



int main(int argc, char **argv) {
   yyparse();
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}
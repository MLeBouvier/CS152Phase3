%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <cstring>
 #include <vector>
 #include <iostream>
 #include <vector> 
 #include <cstring>

 using namespace std;
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 int tempCount = 0;
 extern FILE * yyin;
 int yylex(void);
 vector <string> variables;
 
 

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
%type <str> idents


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

function      :  FUNCTION  ident SEMICOLON {cout << "func " << variables.at(variables.size() - 1) << endl;}
BEGIN_PARAMS declarationsParam END_PARAMS BEGIN_LOCALS declarations END_LOCALS
                  BEGIN_BODY statements END_BODY 
              ;

declarations :  
              |   declaration SEMICOLON declarations
              ;
        
declaration  :	idents COLON INTEGER {cout << '.' << variables.at(variables.size() - 1) << endl;}
              |   idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
		
	      ;

declarationsParam :  
              |   declarationParam SEMICOLON declarationsParam
              ;
        
declarationParam  :	idents COLON INTEGER {cout << '.' << variables.at(variables.size() - 1) << endl << "= " << variables.at(variables.size() - 1) << ", $0" << endl << ". __temp__" << tempCount - 2 << endl << "= __temp__" << tempCount - 2 << ", " << variables.at(variables.size() - 1) << endl;}
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
/* put this in the correct place in the code above {printf("= __temp__%d\n", tempCount - 1);} */
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

comp         :   EQ   {printf("=="), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 1) << ", __temp__" << tempCount-1 << endl;}

              |  NEQ   {printf("!="), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 3) << ", __temp__" << tempCount-1 << endl;}

              |  LT   {printf("<"), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 3) << ", __temp__" << tempCount-1 << endl;}

              |  GT   {printf(">"), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 3) << ", __temp__" << tempCount-1 << endl;}

              |  LTE  {printf("<="), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 3) << ", __temp__" << tempCount-1 << endl;}
              |  GTE  {printf(">="), printf(" __temp__%d",tempCount-1), printf(", __temp__%d",tempCount - 3), printf(", __temp__%d\n",tempCount - 2), cout << "?:= __label__" << (tempCount - 3) << ", __temp__" << tempCount-1 << endl;}
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

              
ident        :    IDENTIFIER    {variables.push_back($1), tempCount = tempCount + 1;} /*tempcount is now the count for the next temp not the current one. check the output format for necessary error checks*/
              ;
%%



int main(int argc, char **argv) {
   yyparse();
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <cstring>
 #include <vector>
 #include <iostream>
 #include <vector> 
 #include <string>
 using namespace std;
 
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 extern FILE * yyin;
 int yylex(void);
 
 int tempCount = 0;
 int labelCount = 0;
 vector <string> variables;
 vector <string> equations;
 vector <string> CallStack;
 vector <string> TempStack;
 vector <string> LabelStack;
 
 void mathOp(string);
 void printBranch();
 
%}

%union{
  double dval;
  int ival;
  char* str;
}

%error-verbose
%start program
%token <str> MULT DIV PLUS MINUS MOD EQUAL L_PAREN R_PAREN END
%token <str> PROGRAM BEGIN_PROGRAM END_PROGRAM ELSEIF FUNCTION BEGIN_PARAMS END_PARAMS
%token <str> BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY
%token <str> OF IF THEN ENDIF ELSE WHILE DO FOREACH IN BEGINLOOP ENDLOOP CONTINUE
%token <str> READ WRITE AND OR NOT TRUE FALSE RETURN
%token <str> EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_SQUARE_BRACKET R_SQUARE_BRACKET
%token <str> ASSIGN 
%token <dval> NUMBER
%token <str> IDENTIFIER

%type <str> idents
%type <str> ident
%type <str> relation-exp
%type <str> expression
%type <str> mult-exp
%type <str> term
%type <str> var
%type <str> paramDecl
%type <str> declaration

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

function      :  FUNCTION  ident SEMICOLON {cout << "func " << variables.back() << endl; variables.pop_back();}
BEGIN_PARAMS paramDecls END_PARAMS BEGIN_LOCALS declarations END_LOCALS
                  BEGIN_BODY statements END_BODY {cout << "endfunc\n\n";}
              ;

paramDecls   :  
              |   paramDecl SEMICOLON paramDecls
              ;
        
paramDecl    :	idents COLON INTEGER  {
                  cout << ". " << variables.back() << endl;
                  cout << "= " << variables.back() << ", $0" << endl; 
                  variables.pop_back();
                } 
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
                  string s = $1;
                  int l = s.find("[");
                  int r = s.find("]");
                  s = s.substr(l,r);
                  cout << ".[] " << variables.back() << ", " << s << endl;
                  variables.pop_back();
                }  
	      ;

declarations :  
              |   declaration SEMICOLON declarations
              ;
        
declaration  :	idents COLON INTEGER {
                  for( int i = 0; i < variables.size(); i++){
                    cout << ". " << variables.at(i) << endl;
                  }
                  variables.clear();
                }
              | idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
                  string s = $1;
                  int l = s.find("[")+1;
                  int r = s.find("]");
                  s = s.substr(l,r-l);
                  cout << ".[] " << variables.back() << ", " << s << endl;
                  variables.pop_back();
                }  
		          ;
                       
statements   :   
              |  statement SEMICOLON statements 
              ;
                       
statement    :    var ASSIGN expression {
                    cout << "= " << variables.back() << ", " << TempStack.back() << endl;
                    variables.pop_back();
                    TempStack.pop_back();
                  }
              |   IF bool-exp {printBranch();} THEN statement SEMICOLON statements ENDIF { 
                    cout << ": __label__" << labelCount << endl;
                  }
              |   IF bool-exp {printBranch();} THEN statement SEMICOLON statements ELSE statements ENDIF { 
                    cout << ": __label__" << labelCount << endl;
                  }                
              |   WHILE bool-exp BEGINLOOP statement SEMICOLON statements ENDLOOP{
                    
                    //  string label_3rd = "__label__" + to_string(labelCount+2);
                    //  string label_2nd = "__label__" + to_string(labelCount+1);
                    //  string label_1st = "__label__" + to_string(labelCount);
                    //  labels.push_back(label_1st)
                    //  labels.push_back(label_2nd)
                    //  labels.push_back(label_3rd)
                    // labelCount += 3
                    
                    //  code << ": " << labels.at(end) << endl; 
                    //  code << code from bool-exp
                    //  code << "?: " << labels.at(end-2) << ", " << TempStack.back() << endl;
                    //  code << ":= " << labels.at(end-1) << endl;
                    //  code << ": " <<  labels.at(end-2) << endl;
                    //  code << code from statement 
                    //  code << code from statements
                    //  code << ":= " << labels.at(end) << endl;
                    //  code << ": " << labels.at(end-2) << endl;   
                    //  $$ = code         
                  }
              |   DO BEGINLOOP statement SEMICOLON statements ENDLOOP WHILE bool-exp                
              |   READ vars {
                    cout << ".< " << variables.back() << endl;
                    variables.pop_back();
                  }
              |   WRITE vars {
                    cout << ".> " << variables.back() << endl;
                    variables.pop_back();
                  }
              |   CONTINUE 
              |   RETURN expression {
                    cout << "ret " << TempStack.back() << endl;
                    TempStack.pop_back();
                  } 
              ;
              
vars         :    var 
              |   vars COMMA var 
              ;
      
var          :    ident  
              |   ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET
              ;

bool-exp      :   relation-and-exp 
              |   bool-exp OR relation-and-exp  
              ;

relation-and-exp :  relation-exp 
                  |  relation-and-exp AND relation-exp 
                  ;

relation-exp  :  NOT relation-exp %prec NOT 
              |  expression comp expression {
                  string temp = "__temp__" + to_string(tempCount);
                  string src2 = TempStack.back();
                   TempStack.pop_back();
                  string src1 = TempStack.back();
                   TempStack.pop_back();
                  
                  cout << ". " << temp << endl;
                  cout << equations.back() << temp << ", " << src1 << ", " << src2 << endl; 
                  
                  equations.pop_back();
                  TempStack.push_back(temp);
                  tempCount++;
                }
              |  TRUE  
              |  FALSE  
              |  L_PAREN bool-exp R_PAREN 
              ;

comp         :   EQ   {equations.push_back("== ");} 
              |  NEQ  {equations.push_back("!= ");} 
              |  LT   {equations.push_back("< ");} 
              |  GT   {equations.push_back("> ");} 
              |  LTE  {equations.push_back("<= ");} 
              |  GTE  {equations.push_back(">= ");} 
              ;
             
expressions   :  expression 
              |  expression COMMA expressions  
              ;        
              
expression   :    mult-exp 
              |   expression PLUS mult-exp {mathOp("+ ");}
              |   expression MINUS mult-exp {mathOp("- ");}
              ;
              
mult-exp     :    term 
              |   mult-exp MULT term {mathOp("* ");}
              |   mult-exp DIV term {mathOp("/ ");}
              |   mult-exp MOD term {mathOp("% ");}
              ;

term         :    MINUS term %prec UMINUS //{++tempCount, cout << "= __temp__ " << (tempCount - 1) << ",  " << $1 << endl;}
              |   NUMBER {
                    string temp = "__temp__" + to_string(tempCount);
                    cout << ". " << temp << endl;
                    cout << "= " << temp << ", " << $1 << endl;
                    TempStack.push_back(temp);
                    ++tempCount;
                  }
              |   var {
                    string temp = "__temp__" + to_string(tempCount);
                    cout << ". " << temp << endl;
                    cout << "= " << temp << ", " << variables.back() << endl;
                    variables.pop_back();
                    TempStack.push_back(temp);
                    ++tempCount;
                  }
              |   L_PAREN expression R_PAREN 
              |   ident L_PAREN {CallStack.push_back($1);} expressions R_PAREN {
                    cout << "param " << TempStack.back() << endl;
                    TempStack.pop_back();
                    string temp = "__temp__" + to_string(tempCount);
                    
                    cout << ". " << temp << endl;
                    string s = CallStack.back();
                    s = s.substr(0,s.size()-2); //gets rid of L_PAREN
                    cout << "call " << s << ", " << temp << endl;
                    
                    TempStack.push_back(temp);
                    CallStack.pop_back();
                    variables.pop_back();
                    tempCount++;
                  } 
              |   ident L_PAREN {CallStack.push_back($1);} R_PAREN {
                    string temp = "__temp__" + to_string(tempCount);
                    
                    cout << ". " << temp << endl;
                    string s = CallStack.back();
                    s = s.substr(0,s.size()-2);
                    cout << "call " << s << ", __temp__" << tempCount << endl;
                    
                    TempStack.push_back(temp);
                    CallStack.pop_back();
                    variables.pop_back();
                    tempCount++;
                  }                    
              ;
              
idents       :    ident 
              |   ident COMMA idents 
		          ;

              
ident        :    IDENTIFIER    {variables.push_back($1);} /*tempcount is now the count for the next temp not the current one. check the output format for necessary error checks maybe need to update the tempCount in a bunch of other functions and not in this one?*/
              ;
%%

int main(int argc, char **argv) {
   yyparse();
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

void mathOp(string op) {
  string temp = "__temp__" + to_string(tempCount);
  string src2 = TempStack.back();
    TempStack.pop_back();
  string src1 = TempStack.back();
    TempStack.pop_back();
  
  
  cout << ". " << temp << endl;
  cout << op << temp << ", " << src1 << ", " << src2 << endl;
  
  TempStack.push_back(temp);
  tempCount++;
}

void initLoop() {
  string label_3rd = "__label__" + to_string(labelCount+2);
  string label_2nd = "__label__" + to_string(labelCount+1);
  string label_1st = "__label__" + to_string(labelCount);
  
  cout << ": " << label_3rd << endl;
  LabelStack.push_back(label_1st);
  LabelStack.push_back(label_2nd);
  LabelStack.push_back(label_3rd);
}

void printBranch() {
  cout << "?:= __label__" << labelCount << ", " << TempStack.back() << endl;
  cout << ":= __label__" << labelCount+1 << endl;
  cout << ": __label__" << labelCount << endl;
  labelCount++;
}
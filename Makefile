parse: mini_l.lex mini_l.y
	bison -v -d --file-prefix=y mini_l.y
	flex mini_l.lex 
	g++ -o parser -std=c++11 y.tab.c lex.yy.c -lfl
		
clean:
	rm -f lex.yy.c parser y.tab.c y.tab.h y.output
compiler: lex.yy.o y.tab.o symbol_table.o code_generator.o main.o token_node.o
	g++ lex.yy.o y.tab.o code_generator.o symbol_table.o token_node.o main.o -o compiler -static-libgcc -static-libstdc++

y.tab.cc: parser.yy
	bison -b y parser.yy

lex.yy.cc: scanner.l y.tab.cc
	flex scanner.l

lex.yy.o: lex.yy.cc
	g++ -c -g lex.yy.cc

y.tab.o: y.tab.cc
	g++ -c -g y.tab.cc

main.o: main.cc
	g++ -c -g main.cc

symbol_table.o: symbol_table.cpp
	g++ -c -g symbol_table.cpp

code_generator.o: code_generator.cpp
	g++ -c -g code_generator.cpp

token_node.o: token_node.cpp location.hh
	g++ -c -g token_node.cpp

clean:
	rm -f location.hh position.hh stack.hh
	rm -f lex.yy.c* y.tab.*
	rm -f *.o compiler
	rm -f *.class *.jasm

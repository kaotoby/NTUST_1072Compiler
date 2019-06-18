/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

%option c++
%option noyywrap
%option yyclass="yy::FlexScanner"

digit       [0-9]
letter      [a-zA-Z]
integer     [+-]?{digit}+
real        [+-]?{digit}*\.{digit}+([Ee][+-]?{digit}+)?
identifier  {letter}({letter}|{digit})*
string      \"([^\"\n]|\"\")*\"

%{
#include "lex.yy.hh"
#include "y.tab.hh"

using namespace yy;

#undef YY_DECL
#define	YY_DECL \
    int yy::FlexScanner::yylex( \
	yy::BisonParser::semantic_type* yylval, \
	yy::BisonParser::location_type* yylloc \
    )


#define MAX_LINE_LENG 65535

// Marcos
#define LIST                  { strcat(buf, yytext); yylloc->columns(yyleng); }
#define LINE           { if (showLine) { printf("%d: %s", yylloc->end.line, buf); } buf[0]='\0'; yylloc->lines(); }
#define token(t, p)           { LIST; if (isVerbose) { printf("<%s>\n", #p); } return (BisonParser::token::t); }
#define tokenInteger(t, p, i) { LIST; if (isVerbose) { printf("<%s:%s>\n", #p, i); } yylval->iValue = atoi(yytext); return (BisonParser::token::t); }
#define tokenReal(t, p, f)    { LIST; if (isVerbose) { printf("<%s:%s>\n", #p, f); } yylval->fValue = atof(yytext); return (BisonParser::token::t); }
#define tokenString(t, p, s)  { LIST; if (isVerbose) { printf("<%s:%s>\n", #p, s); } yylval->sValue = strdup(s); return (BisonParser::token::t); }

char buf[MAX_LINE_LENG];
char stringTokenBuf[MAX_LINE_LENG];

%}

%%

%{
    // reset location
    yylloc->step();
%}

 /* Comments */

"//".*  {LIST;}

\(\*([^*]|(\*+[^*)]))*\*+\) {
    // Split comment by \n
    int idx = strlen(buf);
    for (int i = 0; i < strlen(yytext); i++) {
        buf[idx++] = yytext[i];
        if (yytext[i] == '\n') {
            buf[idx] = '\0';
            idx = 0;
            LINE;
        }
    }
    buf[idx] = '\0';
}

 /* Keywords */

(?i:array)      {token(KW_ARRAY, ARRAY);}
(?i:boolean)    {token(KW_BOOLEAN, BOOLEAN);}
(?i:begin)      {token(KW_BEGIN, BEGIN);}
(?i:by)         {token(KW_BY, BY);}
 /* (?i:break)      {token(KW_BREAK, BREAK);} */
 /* (?i:char)       {token(KW_CHAR, CHAR);} */
 /* (?i:case)       {token(KW_CASE, CASE);} */
(?i:const)      {token(KW_CONST, CONST);}
(?i:continue)   {token(KW_CONTINUE, CONTINUE);}
(?i:do)         {token(KW_DO, DO);}
(?i:else)       {token(KW_ELSE, ELSE);}
(?i:elsif)      {token(KW_ELSIF, ELSIF);}
(?i:end)        {token(KW_END, END);}
(?i:exit)       {token(KW_EXIT, EXIT);}
(?i:false)      {token(KW_FALSE, FALSE);}
(?i:for)        {token(KW_FOR, FOR);}
 /* (?i:fn)         {token(KW_FN, FN);} */
(?i:if)         {token(KW_IF, IF);}
 /* (?i:in)         {token(KW_IN, IN);} */
(?i:integer)    {token(KW_INTEGER, INTEGER);}
(?i:loop)       {token(KW_LOOP, LOOP);}
(?i:module)     {token(KW_MODULE, MODULE);}
(?i:print)      {token(KW_PRINT, PRINT);}
(?i:println)    {token(KW_PRINTLN, PRINTLN);}
(?i:procedure)  {token(KW_PROCEDURE, PROCEDURE);}
(?i:repeat)     {token(KW_REPEAT, REPEAT);}
(?i:return)     {token(KW_RETURN, RETURN);}
(?i:real)       {token(KW_REAL, REAL);}
(?i:string)     {token(KW_STRING, STRING);}
 /* (?i:record)     {token(KW_RECORD, RECORD);} */
(?i:then)       {token(KW_THEN, THEN);}
(?i:true)       {token(KW_TRUE, TRUE);}
(?i:to)         {token(KW_TO, TO);}
 /* (?i:type)       {token(KW_TYPE, TYPE);} */
 /* (?i:use)        {token(KW_USE, USE);} */
(?i:until)      {token(KW_UNTIL, UNTIL);}
(?i:var)        {token(KW_VAR, VAR);}
(?i:while)      {token(KW_WHILE, WHILE);}
(?i:of)         {token(KW_OF, OF);}
(?i:read)       {token(KW_READ, READ);}

 /* Delimiters */

","             {token(COMMA, ',');}
":"             {token(COLON, ':');}
"."             {token(PERIOD, '.');}
";"             {token(SEMICOLON, ';');}

"("             {token(LEFT_PARENTHESIS, '(');}
")"             {token(RIGHT_PARENTHESIS, ')');}
"["             {token(LEFT_SQUARE_BRACKET, '[');}
"]"             {token(RIGHT_SQUARE_BRACKET, ']');}
"{"             {token(LEFT_CURLY_BRACKET, '{');}
"}"             {token(RIGHT_CURLY_BRACKET, '}');}

 /* Operators */

"+"             {token(PLUS, '+');}
"-"             {token(HYPHEN_MINUS, '-');}
"*"             {token(ASTERISK, '*');}
"/"             {token(SOLIDUS, '/');}

"%"             {token(PERCENT, '%');}

"<"             {token(LESS_THAN, '<');}
"<="            {token(LESS_EQUAL_THAN, '<=');}
">"             {token(GREATER_THAN, '>');}
">="            {token(GREATER_EQUAL_THAN, '>=');}
"="             {token(EQUAL, '=');}
"<>"            {token(NOT_EQUAL, '<>');}

"&&"            {token(LOGICAL_AND, '&&');}
"||"            {token(LOGICAL_OR, '||');}
"~"             {token(TILDE, '~');}
":="            {token(ASSIGNMENT, ':=');}

 /* Values */

{real}          {tokenReal(REAL, real, yytext);}
{integer}       {tokenInteger(INTEGER, integer, yytext);}

{string} {
    int idx = 0;
    // Replace 2 float quotes("") to 1 float quote(")
    for (int i = 1; i < strlen(yytext) - 1; i++) {
        if (yytext[i] == '"' && yytext[i + 1] == '"') {
            i++;
        }
        stringTokenBuf[idx++] = yytext[i];
    }
    stringTokenBuf[idx] = '\0';
    tokenString(STRING, string, stringTokenBuf);    
}

 /* Identifier */

{identifier} { tokenString(IDENTIFIER, identifier, yytext); }

 /* Spaces */

[ \t\v\f]*  {LIST; yylloc->step(); }

 /* New Line */

\n      {
            LIST; LINE; 
            yylloc->step();
        }

 /* EOF */

<<EOF>> {
    // Handle when there's no \n at the end of file
    if (buf[0] != '\0') {
        LIST;
        LINE;
        printf("\n");
    }
    
    yyterminate();
}

 /* Bad character */

. {
    LINE;
    printf("\nbad character:'%s'\n",yytext);
    exit(-1);
}

%%

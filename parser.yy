%{
/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#include <iostream>
#include <map>
#include <vector>
#include <stack>
#include <string>
#include "driver.h"
#include "token_node.h"
#include "symbol_table.h"

#define Trace(s, t) { if (isVerbose) std::cout << "[YACC] "<< s << " -> " << t << std::endl; }
#define Warn(loc, s) { error(loc, std::string("WARNING: ") + (s)); (*warningCount)++; }

#define ValidateDuplicateIdentifier(loc, s, e) { if (localSymbolTable->HasKey(s)) { Warn(loc, "Duplicate identifier found at scope "+localSymbolTable->scope+": "+s); } }
#define ValidateEntryType(loc, t, et) { if (t != et) { Warn(loc, "Invalid entry type: "+EnumToString(t)+", Expect: "+EnumToString(et)); } }
#define ValidateValueType(loc, t, et) { if (t != et) { Warn(loc, "Invalid value type: "+EnumToString(t)+", Expect: "+EnumToString(et)); } }
#define ValidateValueType2(loc, t, et1, et2) { if (t != et1 && t != et2) { Warn(loc, "Invalid value type: "+EnumToString(t) + ", Expect: "+EnumToString(et1)+" or "+EnumToString(et2)); } }
#define ValidateValueTypeNot(loc, t, et) { if (t == et) { Warn(loc, "Invalid value type: "+EnumToString(t)); } }
#define ValidateValueTypeSame(loc, n1, n2) { if (n1->valueType != n2->valueType) { Warn(loc, "Value type mismatch: "+EnumToString(n1->valueType) + ", " +EnumToString(n2->valueType)); } }

#define MakeIdentifierNode(loc, k, n) TokenNode* n = new TokenNode(loc); { \
    n->operatorType = OperatorType::IdentifierValue; \
    if (localSymbolTable->HasKey(k)) { \
        n->symbolTableEntry = localSymbolTable->Find(k); \
        n->valueType = n->symbolTableEntry->valueType; \
    } else if (globalSymbolTable->HasKey(k)) { \
        n->symbolTableEntry = globalSymbolTable->Find(k); \
        n->valueType = n->symbolTableEntry->valueType; \
    } else { Warn(loc, "Identifier not found: " + std::string(k)); } \
}

#define MakeStatementNode(loc, k, n) TokenNode* n = new TokenNode(loc); { \
    n->operatorType = OperatorType::Statement; \
    n->valueType = k->valueType; \
    n->exp1 = k; \
}

SymbolTable* localSymbolTable;
SymbolTable* globalSymbolTable;
std::stack<TokenNode*> loopStack;

%}
/* Enable C++ Skeleton */
%skeleton "lalr1.cc"
/* Enable yyloc support */
%locations
/* Enable header file output */
%defines
/* Set output class name to BisonParser */
%define parser_class_name {BisonParser}

/* Code inside y.tab.hh */
%code requires {
    #include "driver.h"
    #include "symbol_table.h"
    #include "token_node.h"
    // Forward declarations required classes, since we need to inject scanner into praser
    namespace yy {
        class FlexScanner;
        class BisonParser;
    }

    struct SymbolTableEntryListItem {
        struct SymbolTableEntryListItem* next;
        SymbolTableEntry* entry;
    };
    typedef struct SymbolTableEntryListItem SymbolTableEntryListItem;

}
/* Inject scanner into praser */
%parse-param {FlexScanner &scanner}
%parse-param {std::map<std::string, SymbolTable*> &symbolTableMap}
%parse-param {bool isVerbose}
%parse-param {int* warningCount}
%parse-param {TokenNode* programNode}
%code {
    #include "lex.yy.hh"
    #undef yylex
    #define yylex scanner.yylex
}
/* Union variables for each node */
%union 	{
	int iValue;
	float fValue;
	char *sValue;
    bool bValue;
    ValueType valueType;
    SymbolTableEntryListItem* sValueList;
    SymbolTableEntry* symbolTableEntry;
    TokenNode* token;
}

/* Keywords */
%token KW_ARRAY KW_BOOLEAN KW_BEGIN KW_BY KW_CONST KW_CONTINUE
%token KW_DO KW_ELSE KW_ELSIF KW_END KW_EXIT KW_FALSE KW_FOR KW_IF KW_INTEGER
%token KW_LOOP KW_MODULE KW_OF KW_PRINT KW_PRINTLN KW_PROCEDURE
%token KW_READ KW_REPEAT KW_RETURN KW_REAL KW_STRING
%token KW_THEN KW_TO KW_TRUE KW_UNTIL KW_VAR KW_WHILE

/* Delimiters */
%token COMMA COLON PERIOD SEMICOLON
%token LEFT_PARENTHESIS RIGHT_PARENTHESIS
%token LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
%token LEFT_SQUARE_BRACKET RIGHT_SQUARE_BRACKET

/* Operators */
%token PLUS HYPHEN_MINUS
%token ASTERISK SOLIDUS PERCENT
%token LESS_THAN LESS_EQUAL_THAN
%token GREATER_THAN GREATER_EQUAL_THAN
%token EQUAL NOT_EQUAL
%token LOGICAL_AND LOGICAL_OR
%token TILDE
%token ASSIGNMENT

/* Value */
%token IDENTIFIER
%token INTEGER
%token REAL
%token STRING

/* Associativity */
%nonassoc LESS_THAN LESS_EQUAL_THAN GREATER_THAN GREATER_EQUAL_THAN EQUAL NOT_EQUAL
%left PLUS HYPHEN_MINUS
%left ASTERISK SOLIDUS PERCENT

/* Type Declarations */
%type <sValue> STRING IDENTIFIER
%type <iValue> INTEGER
%type <fValue> REAL
%type <bValue> boolean
%type <sValueList> variable_identifier_list
%type <valueType> type_specifier return_type_optional
%type <symbolTableEntry> const_declarator array_specifier variable_type_specifier
%type <token> constant array_item function_call argument_expression_list argument_expression_list_optional function_declaration function_declaration_list function_declaration_list_optional
%type <token> expression primary_expression postfix_expression unary_expression multiplicative_expression additive_expression relational_expression not_expression logical_and_expression logical_or_expression conditional_expression
%type <token> statement_list_optional statement_list statement assignable_item assignment_statement print_statement read_statement return_statement
%type <token> conditional_statement elseif_declaration_list_optional elseif_declaration_list elseif_declaration else_declaration_optional
%type <token> while_statement repeat_statement for_statement by_declaration_optional loop_statement continue_exit_statement function_call_statement

%start program
%%
EMPTY: ;

constant:
      STRING
    {
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::String;
        $$->value.sValue = $1;
    }
    | INTEGER
    {
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Integer;
        $$->value.iValue = $1;
    }
    | REAL
    {
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Float;
        $$->value.fValue = $1;
    }
    | boolean
    {
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Bool;
        $$->value.bValue = $1;
    }
    ;
boolean:
      KW_TRUE { $$ = true; }
    | KW_FALSE { $$ = false; }
    ;
type_specifier:
      KW_STRING  { $$ = ValueType::String; }
    | KW_INTEGER { $$ = ValueType::Integer; }
    | KW_REAL    { $$ = ValueType::Float; }
    | KW_BOOLEAN { $$ = ValueType::Bool; }
    ;
array_specifier:
      KW_ARRAY LEFT_SQUARE_BRACKET INTEGER COMMA INTEGER
    {
        // VALIDATION: Array range
        if ($3 > $5) {
            Warn(@5, "Invalid array range [" + std::to_string($3) + "," + std::to_string($5) + "].");
        }
    }
       RIGHT_SQUARE_BRACKET
       KW_OF type_specifier
    {
        // Make array entry
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->valueType = ValueType::Array;
        entry->arrayEntry.valueType = $9;
        entry->arrayEntry.low = $3;
        entry->arrayEntry.high = $5;
        $$ = entry;
    }
    ;
array_item:
      IDENTIFIER LEFT_SQUARE_BRACKET expression RIGHT_SQUARE_BRACKET
    {
        MakeIdentifierNode(@1, $1, identifier);
        $$ = new TokenNode(@1);
        $$->symbolTableEntry = identifier->symbolTableEntry;
        $$->exp1 = identifier;
        $$->exp2 = $3;

        // VALIDATION: Array index type check
        ValidateValueType(@3, $3->valueType, ValueType::Integer);
        if (identifier->symbolTableEntry != NULL) {
            // VALIDATION: Static arraya index range check
            if ($3->operatorType == OperatorType::ConstValue)
            {
                int idx = $3->value.iValue;
                ArrayEntry arrayEntry = identifier->symbolTableEntry->arrayEntry;
                if (idx < arrayEntry.low || idx > arrayEntry.high)
                {
                    Warn(@3, "Invalid array index for: "+identifier->symbolTableEntry->name+"["+std::to_string(arrayEntry.low)+","+std::to_string(arrayEntry.high)+"] , got: " + std::to_string(idx));
                }
            }
            $$->valueType = identifier->symbolTableEntry->arrayEntry.valueType;
        }
    }
    ;

/* module program */

program:
      KW_MODULE IDENTIFIER
    {
        // Create new symbol table with global scope
        localSymbolTable = new SymbolTable(GLOBAL_SYM_TABLE_NAME);
        symbolTableMap[GLOBAL_SYM_TABLE_NAME] = localSymbolTable;
        globalSymbolTable = localSymbolTable;
    }
        variable_const_declaration_unit
        function_declaration_list_optional
    {
        // Dump global symbol table
        globalSymbolTable->Dump();
    }
        KW_BEGIN
        statement_list_optional
        KW_END IDENTIFIER
        PERIOD
    {
        // VALIDATION: Module begin/end identifier
        std::string begin($2), end($10);
        if (begin != end) {
            Warn(@10, "Begin/End identifier mismatch for module: " + begin + " , got: " + end);
        }
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->name = $2;
        programNode->lineNumber = @1.begin.line;
        programNode->operatorType = OperatorType::Program;
        programNode->exp1 = $5;
        programNode->exp2 = $8;
        programNode->symbolTableEntry = entry;
    }
    ;
variable_const_declaration_unit:
      EMPTY
    | const_declaration
    | const_declaration variable_declaration
    | variable_declaration
    | variable_declaration const_declaration
    ;

/* constant declaration */
const_declaration:
      KW_CONST const_declarator_list
    {
        Trace("const_declaration ", "CONST const_declarator_list");
    }
    ;
const_declarator_list:
      const_declarator
    {
        Trace("const_declarator_list", "const_declarator");
    }
    | const_declarator_list const_declarator
    {
        Trace("const_declarator_list", "const_declarator_list const_declarator");
    }
    ;
const_declarator:
      IDENTIFIER EQUAL constant SEMICOLON
    {
        Trace("const_declarator", "IDENTIFIER = constant;");
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->value = $3->value;
        entry->valueType = $3->valueType;
        entry->entryType = EntryType::Constant;
        entry->name = $1;
        delete($3); // Free TokenNode
        // VALIDATION: Duplicate identifier
        ValidateDuplicateIdentifier(@1, $1, entry);
        localSymbolTable->Add($1, entry);
        $$ = entry;
    }
    ;

/* variable declaration */

variable_declaration:
      KW_VAR variable_declarator_list
    {
        Trace("variable_declaration", "VAR variable_declarator_list");
    }
    ;
variable_declarator_list:
      variable_declarator
    {
        Trace("variable_declarator_list", "variable_declarator");
    }
    | variable_declarator_list variable_declarator
    {
        Trace("variable_declarator_list", "variable_declarator_list variable_declarator");
    }
    ;
variable_type_specifier:
      type_specifier
    {
        Trace("variable_type_specifier", "type_specifier");
        // Make entry
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->valueType = $1;
        entry->entryType = EntryType::Variable;
        $$ = entry;
    }
    | array_specifier
    {
        Trace("variable_type_specifier", "array_specifier");
        $$->entryType = EntryType::Variable;
    }
    ;
variable_declarator:
      variable_identifier_list COLON variable_type_specifier
    {
        Trace("variable_declarator", "variable_identifier_list : variable_type_specifier;");
        // Assign variable type to each entry in list
        SymbolTableEntryListItem* node = $1;
        while (node != NULL)
        {
            SymbolTableEntryListItem* oldNode = node;
            SymbolTableEntry* entry = node->entry;
            entry->valueType = $3->valueType;
            entry->arrayEntry = $3->arrayEntry;
            node = node->next;
            delete(oldNode); // Free link list node
        }
        delete($3); // Free variable_type_specifier
    }
      SEMICOLON
    ;
variable_identifier_list:
      IDENTIFIER
    {
        // Add variable entry to symbol table
        Trace("variable_identifier_list", "IDENTIFIER");
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->name = $1;
        entry->entryType = EntryType::Variable;
        // VALIDATION: Duplicate identifier
        ValidateDuplicateIdentifier(@1, $1, entry);
        localSymbolTable->Add($1, entry);
        // Build variable link list
        $$ = new SymbolTableEntryListItem();
        $$->entry = entry;
    }
    | variable_identifier_list COMMA IDENTIFIER
    {
        // Add variable entry to symbol table
        Trace("variable_identifier_list", "variable_identifier_list, IDENTIFIER");
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->name = $3;
        entry->entryType = EntryType::Variable;
        // VALIDATION: Duplicate identifier
        ValidateDuplicateIdentifier(@3, $3, entry);
        localSymbolTable->Add($3, entry);
        // Build variable link list
        $$ = new SymbolTableEntryListItem();
        $$->entry = entry;
        $$->next = $1;
    }
    ;

/* #region function declarations */

function_declaration:
      KW_PROCEDURE IDENTIFIER
    {
        // Add function entry to symbol table
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->name = $2;
        entry->entryType = EntryType::Function;
        // VALIDATION: Duplicate identifier
        ValidateDuplicateIdentifier(@2, $2, entry);
        localSymbolTable->Add($2, entry);

        // Create new symbol table for function
        localSymbolTable = new SymbolTable($2);
        symbolTableMap[$2] = localSymbolTable;
    }
      formal_argument_optional return_type_optional
    {
        // Assign function return type
        globalSymbolTable->Find($2)->valueType = $5;
    }
        variable_const_declaration_unit
        KW_BEGIN
        statement_list_optional
        KW_END IDENTIFIER
        SEMICOLON
    {
        Trace("function_declaration", "");
        // VALIDATION: Procedure begin/end identifier
        std::string begin($2);
        std::string end($11);
        if (begin != end) {
            Warn(@11, "Begin/End identifier mismatch for procedure: " + begin + " , got " + end + ".");
        }
        // Dump procedure symbol table
        localSymbolTable->Dump();
        localSymbolTable = globalSymbolTable;

        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::FunctionDeclaration;
        $$->symbolTableEntry = globalSymbolTable->Find($2);
        $$->exp1 = $9;
    }
    ;
function_declaration_list_optional:
      EMPTY
    {
        Trace("function_declaration_list_optional", "EMPTY");
        $$ = NULL;
    }
    | function_declaration_list
    {
        Trace("function_declaration_list_optional", "function_declaration_list");
        $$ = $1;
    }
    ;
function_declaration_list:
      function_declaration
    {
        Trace("function_declaration_list", "function_declaration");
        $$ = $1;
        $$->last = $$;
    }
    | function_declaration_list function_declaration
    {
        Trace("function_declaration_list_optional", "function_declaration_list_optional function_declaration");
        $$ = $1;
        $$->last->next = $2;
        $$->last = $2;
    }
    ;
return_type_optional:
      EMPTY
    {
        Trace("return_type_optional", "EMPTY");
        $$ = ValueType::Void;
    }
    | COLON type_specifier
    {
        Trace("return_type_optional", "type_specifier");
        $$ = $2;
    }
    ;
formal_argument_optional:
      EMPTY
    {
        Trace("formal_argument_optional", "EMPTY");
    }
    | LEFT_PARENTHESIS formal_argument_list RIGHT_PARENTHESIS
    {
        Trace("formal_argument_optional", "(formal_argument_list)");
    }
    ;
formal_argument_list:
    | formal_argument
    {
        Trace("formal_argument_list", "formal_argument");
    }
    | formal_argument_list COMMA formal_argument
    {
        Trace("formal_argument_list", "formal_argument_list, formal_argument");
    }
    ;
formal_argument:
      IDENTIFIER
    {
        // Add function argument entry to symbol table
        SymbolTableEntry* entry = new SymbolTableEntry();
        entry->name = $1;
        entry->entryType = EntryType::Argument;
        // VALIDATION: Duplicate identifier
        ValidateDuplicateIdentifier(@1, $1, entry);
        localSymbolTable->Add($1, entry);
    }
      COLON type_specifier
    {
        localSymbolTable->Find($1)->valueType = $4;
    }
    ;

function_call:
      IDENTIFIER LEFT_PARENTHESIS argument_expression_list_optional RIGHT_PARENTHESIS
    {
        Trace("postfix_expression", "IDENTIFIER(argument_expression_list)");
        // VALIDATION: Function declaration
        MakeIdentifierNode(@1, $1, identifier);
        if (identifier->symbolTableEntry != NULL) {
            ValidateEntryType(@1, identifier->symbolTableEntry->entryType, EntryType::Function);
            // VALIDATION: Function arguments and index
            std::vector<SymbolTableEntry*> argumentTable = symbolTableMap[$1]->GetArgumentTable();
            TokenNode* node = $3;
            for (int i = 0; i < argumentTable.size(); i++)
            {
                if (node == NULL)
                {
                    Warn(@3, "Procedure argument mismatch: " + identifier->symbolTableEntry->name + " arg" + std::to_string(i) + " should be type " + EnumToString(argumentTable[i]->valueType) + " , got: void");
                } else {
                    if (node->valueType != argumentTable[i]->valueType)
                    {
                        Warn(@3, "Procedure argument mismatch: " + identifier->symbolTableEntry->name + " arg" + std::to_string(i) + " should be type " + EnumToString(argumentTable[i]->valueType)+" , got: "+EnumToString(node->valueType));
                    }
                    node = node->next;
                }
            }
        }
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::FunctionInvoke;
        $$->valueType = identifier->valueType;
        $$->symbolTableEntry = identifier->symbolTableEntry;
        $$->exp1 = identifier;
        $$->exp2 = $3;
    }
    ;

/* expression */

expression:
      conditional_expression
    {
        $$ = $1;
    }
    ;
primary_expression:
      IDENTIFIER
    {
        Trace("primary_expression", "IDENTIFIER");
        // VALIDATION: Variable declaration
        MakeIdentifierNode(@1, $1, identifier);
        // VALIDATION: Non function
        if (identifier->symbolTableEntry != NULL && identifier->symbolTableEntry->entryType == EntryType::Function) {
            Warn(@1, "Invalid procedure call, can not use procedure as variable: "+identifier->symbolTableEntry->name)
        }
        $$ = identifier;
    }
    | constant
    {
        Trace("primary_expression", "constant");
        $$ = $1;
    }
    | array_item
    {
        Trace("primary_expression", "array_item");
        $$ = $1;
        $$->operatorType = OperatorType::ArrayLoad;
    }
    | LEFT_PARENTHESIS expression RIGHT_PARENTHESIS
    {
        Trace("primary_expression", "(expression)");
        $$ = $2;
    }
    ;
postfix_expression:
	  primary_expression
    {
        Trace("postfix_expression", "primary_expression");
        $$ = $1;
    }
	| function_call
    {
        Trace("postfix_expression", "function_call");
        // VALIDATION: Return type non-null
        if ($1->valueType == ValueType::Void) {
            Warn(@1, "Fuction return type of void is not allowed in expression: " + $1->symbolTableEntry->name)
        }
        $$ = $1;
    }
	;
argument_expression_list_optional:
      EMPTY
    {
        Trace("argument_expression_list_optional", "EMPTY");
        $$ = NULL;
    }
    | argument_expression_list
    {
        Trace("argument_expression_list_optional", "argument_expression_list");
        $$ = $1;
    }
    ;
argument_expression_list:
	  expression
    {
        Trace("argument_expression_list", "expression");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::FunctionArgument;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->last = $$;
    }
	| argument_expression_list COMMA expression
    {
        Trace("argument_expression_list", "argument_expression_list, expression");
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::FunctionArgument;
        node->valueType = $3->valueType;
        node->exp1 = $3;
        $$ = $1;
        $$->last->next = node;
        $$->last = node;
    }
	;
/* precedence 1 */
unary_expression:
      postfix_expression
    {
        Trace("unary_expression", "postfix_expression");
        $$ = $1;
    }
    | HYPHEN_MINUS unary_expression
    {
        Trace("unary_expression", "-unary_expression");
        ValidateValueType2(@2, $2->valueType, ValueType::Integer, ValueType::Float);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Negative;
        $$->valueType = $2->valueType;
        $$->exp1 = $2;
    }
    ;
/* precedence 2 */
multiplicative_expression:
	  unary_expression
    {
        Trace("multiplicative_expression", "unary_expression");
        $$ = $1;
    }
	| multiplicative_expression ASTERISK unary_expression
    {
        Trace("multiplicative_expression", "multiplicative_expression * unary_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Multiply;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| multiplicative_expression SOLIDUS unary_expression
    {
        Trace("multiplicative_expression", "multiplicative_expression / unary_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Devide;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| multiplicative_expression PERCENT unary_expression
    {
        Trace("multiplicative_expression", "multiplicative_expression % unary_expression");
        ValidateValueType(@1, $1->valueType, ValueType::Integer);
        ValidateValueType(@3, $3->valueType, ValueType::Integer);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Reminder;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	;
/* precedence 3 */
additive_expression:
	  multiplicative_expression
    {
        Trace("additive_expression", "multiplicative_expression");
        $$ = $1;
    }
	| additive_expression PLUS multiplicative_expression
    {
        Trace("additive_expression", "additive_expression + multiplicative_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Add;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| additive_expression HYPHEN_MINUS multiplicative_expression
    {
        Trace("additive_expression", "additive_expression - multiplicative_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Minus;
        $$->valueType = $1->valueType;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	;
/* precedence 4 */
relational_expression:
	  additive_expression
    {
        Trace("relational_expression", "additive_expression");
        $$ = $1;
    }
	| relational_expression LESS_THAN additive_expression
    {
        Trace("relational_expression", "relational_expression < additive_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::LessThen;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| relational_expression LESS_EQUAL_THAN additive_expression
    {
        Trace("relational_expression", "relational_expression > additive_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::LessEqualThen;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| relational_expression GREATER_THAN additive_expression
    {
        Trace("relational_expression", "relational_expression <= additive_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::GreaterThen;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| relational_expression GREATER_EQUAL_THAN additive_expression
    {
        Trace("relational_expression", "relational_expression >= additive_expression");
        ValidateValueType2(@1, $1->valueType, ValueType::Integer, ValueType::Float);
        ValidateValueType2(@3, $3->valueType, ValueType::Integer, ValueType::Float);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::GreaterEqualThen;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| relational_expression EQUAL additive_expression
    {
        Trace("relational_expression", "relational_expression = additive_expression");
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Equal;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	| relational_expression NOT_EQUAL additive_expression
    {
        Trace("relational_expression", "relational_expression <> additive_expression");
        ValidateValueTypeSame(@2, $1, $3);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::NotEqual;
        $$->valueType = ValueType::Bool;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
	;
/* precedence 5 */
not_expression:
	  relational_expression
    {
        Trace("not_expression", "relational_expression");
        $$ = $1;
    }
	| TILDE not_expression
    {
        Trace("not_expression", "~not_expression");
        ValidateValueType(@2, $2->valueType, ValueType::Bool);
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::LogicalNot;
        node->valueType = ValueType::Bool;
        node->exp1 = $2;
        $$ = node;
    }
	;
/* precedence 6 */
logical_and_expression:
	  not_expression
    {
        Trace("logical_and_expression", "not_expression");
        $$ = $1;
    }
	| logical_and_expression LOGICAL_AND not_expression
    {
        Trace("logical_and_expression", "logical_and_expression && not_expression");
        ValidateValueType(@1, $1->valueType, ValueType::Bool);
        ValidateValueType(@3, $3->valueType, ValueType::Bool);
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::LogicalAnd;
        node->valueType = ValueType::Bool;
        node->exp1 = $1;
        node->exp2 = $3;
        $$ = node;
    }
	;
/* precedence 7 */
logical_or_expression:
	  logical_and_expression
    {
        Trace("logical_or_expression", "logical_and_expression");
        $$ = $1;
    }
	| logical_or_expression LOGICAL_OR logical_and_expression
    {
        Trace("logical_or_expression", "logical_or_expression || logical_and_expression");
        ValidateValueType(@1, $1->valueType, ValueType::Bool);
        ValidateValueType(@3, $3->valueType, ValueType::Bool);
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::LogicalOr;
        node->valueType = ValueType::Bool;
        node->exp1 = $1;
        node->exp2 = $3;
        $$ = node;
    }
	;
conditional_expression:
	  logical_or_expression
    {
        Trace("conditional_expression", "logical_or_expression");
        $$ = $1;
    }
	;

/* statements */

statement_list_optional:
      EMPTY
    {
        Trace("statement_list_optional", "EMPTY");
        $$ = NULL;
    }
    | statement_list
    {
        Trace("statement_list_optional", "statement_list");
        $$ = $1;
    }
    ;
statement_list:
      statement
    {
        Trace("statement_list", "statement");
        $$ = $1;
        $$->last = $$;
    }
    | statement_list statement
    {
        Trace("statement_list", "statement_list_optional statement");
        $$ = $1;
        $$->last->next = $2;
        $$->last = $2;
    }
    ;
statement:
      assignment_statement SEMICOLON
    {
        Trace("statement", "assignment_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | print_statement SEMICOLON
    {
        Trace("statement", "print_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | read_statement SEMICOLON
    {
        Trace("statement", "read_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | return_statement SEMICOLON
    {
        Trace("statement", "return_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | conditional_statement SEMICOLON
    {
        Trace("statement", "conditional_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | while_statement SEMICOLON
    {
        Trace("statement", "while_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | repeat_statement SEMICOLON
    {
        Trace("statement", "repeat_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | for_statement SEMICOLON
    {
        Trace("statement", "for_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | loop_statement SEMICOLON
    {
        Trace("statement", "loop_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | continue_exit_statement SEMICOLON
    {
        Trace("statement", "continue_exit_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    | function_call_statement SEMICOLON
    {
        Trace("statement", "function_call_statement");
        MakeStatementNode(@1, $1, node);
        $$ = node;
    }
    ;
assignable_item:
     IDENTIFIER
    {
        Trace("assignable_item", "IDENTIFIER");
        // VALIDATION: Variable declaration
        MakeIdentifierNode(@1, $1, identifier);
        // VALIDATION: Assignable types
        ValueType valueType = identifier->valueType;
        if (valueType != ValueType::Integer && valueType != ValueType::Float && valueType != ValueType::Bool && valueType != ValueType::String)
        {
            Warn(@1, "Can not assign type: " + EnumToString(valueType));
        }
        // VALIDATION: Non const
        if (identifier->symbolTableEntry != NULL && identifier->symbolTableEntry->entryType == EntryType::Constant) {
            Warn(@1, "Can not re-assign constant variable: "+identifier->symbolTableEntry->name)
        }
        $$ = identifier;
    }
    | array_item
    {
        Trace("assignable_item", "array_item");
        $$ = $1;
        $$->operatorType = OperatorType::ArrayStore;
    }
    ;
assignment_statement:
      assignable_item ASSIGNMENT expression
    {
        Trace("assignment_statement", "assignable_item := expression");
        // VALIDATION: Same type check
        ValidateValueTypeSame(@3, $1, $3);

        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Assign;
        $$->exp1 = $1;
        $$->exp2 = $3;
    }
    ;
print_statement:
      KW_PRINT expression
    {
        Trace("print_statement", "PRINT expression");
        ValueType valueType = $2->valueType;
        // VALIDATION: Printable types
        if (valueType != ValueType::Integer && valueType != ValueType::Float && valueType != ValueType::Bool && valueType != ValueType::String)
        {
            Warn(@2, "Can not print type: " + EnumToString(valueType));
        }
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Print;
        $$->exp1 = $2;
    }
    | KW_PRINTLN expression
    {
        Trace("print_statement", "PRINTLN expression");
        ValueType valueType = $2->valueType;
        // VALIDATION: Printable types
        if (valueType != ValueType::Integer && valueType != ValueType::Float && valueType != ValueType::Bool && valueType != ValueType::String)
        {
            Warn(@2, "Can not print type: " + EnumToString(valueType));
        }
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::PrintLine;
        $$->exp1 = $2;
    }
    ;
read_statement:
      KW_READ assignable_item
    {
        Trace("print_statement", "READ IDENTIFIER");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Read;
        $$->exp1 = $2;
    }
    ;
return_statement:
      KW_RETURN
    {
        Trace("return_statement", "RETURN");
        // VALIDATION: Return type
        if (localSymbolTable->scope != GLOBAL_SYM_TABLE_NAME)
        {
            ValueType returnType = globalSymbolTable->Find(localSymbolTable->scope)->valueType;
            if (ValueType::Void != returnType)
            {
                Warn(@1, "Precedure return type mismatch: "+localSymbolTable->scope+", Expect: "+EnumToString(returnType)+" , got: "+EnumToString(ValueType::Void));
            }
        }
        $$ = new TokenNode(@1);
        $$->valueType = ValueType::Void;
        $$->operatorType = OperatorType::Return;
    }
    | KW_RETURN expression
    {
        Trace("return_statement", "RETURN expression");
        // VALIDATION: Return type
        if (localSymbolTable->scope != GLOBAL_SYM_TABLE_NAME)
        {
            ValueType returnType = globalSymbolTable->Find(localSymbolTable->scope)->valueType;
            if ($2->valueType != returnType)
            {
                Warn(@2, "Precedure return type mismatch: "+localSymbolTable->scope+", Expect: "+EnumToString(returnType)+" , got: "+EnumToString($2->valueType));
            }
        }
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Return;
        $$->valueType = $2->valueType;
        $$->exp1 = $2;
    }
    ;
conditional_statement:
      KW_IF expression KW_THEN statement_list_optional elseif_declaration_list_optional else_declaration_optional KW_END
    {
        Trace("conditional_statement", "IF (expression) THEN statements else_declaration_optional END");
        ValidateValueType(@2, $2->valueType, ValueType::Bool);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::If;
        $$->exp1 = $2; // condition
        $$->exp2 = $4; // statements
        $$->exp3 = $6; // else
        $$->next = $5; // elseif
        
        TokenNode* node = $$->next;
        while(node != NULL)
        {
            node->parent = $$;
            node = node->next;
        }
    }
    ;
elseif_declaration_list_optional:
      EMPTY
    {
        Trace("elseif_declaration_list_optional", "EMPTY");
        $$ = NULL;
    }
    | elseif_declaration_list
    {
        Trace("elseif_declaration_list_optional", "elseif_declaration_list");
        $$ = $1;
    }
    ;
elseif_declaration_list:
      elseif_declaration
    {
        Trace("elseif_declaration_list", "ELSIF (expression) THEN statements");
        $$ = $1;
        $$->last = $$;
    }
    | elseif_declaration_list elseif_declaration
    {
        Trace("else_declaration_optional", "elseif_declaration_list ELSIF (expression) THEN statements");
        $$ = $1;
        $$->last->next = $2;
        $$->last = $2;
    }
    ;
elseif_declaration:
      KW_ELSIF expression KW_THEN statement_list_optional
    {
        ValidateValueType(@2, $2->valueType, ValueType::Bool);
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ElseIf;
        $$->exp1 = $2; // condition
        $$->exp2 = $4; // statements
    }
    ;
else_declaration_optional:
      EMPTY
    {
        Trace("else_declaration_optional", "EMPTY");
        $$ = NULL;
    }
    | KW_ELSE statement_list_optional
    {
        Trace("else_declaration_optional", "KW_ELSE statement_list_optional");
        $$ = $2;
    }
    ;
while_statement:
      KW_WHILE expression KW_DO
    {
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::While;
        loopStack.push(node);
    } statement_list_optional KW_END
    {
        ValidateValueType(@2, $2->valueType, ValueType::Bool);
        Trace("while_statement", "WHILE (expression) DO statement_list_optional END");
        $$ = loopStack.top();
        loopStack.pop();
        $$->exp1 = $2; // condition
        $$->exp2 = $5; // statements
    }
    ;
repeat_statement:
      KW_REPEAT {
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::Repeat;
        loopStack.push(node);
    } statement_list_optional KW_UNTIL expression
    {
        ValidateValueType(@5, $5->valueType, ValueType::Bool);
        Trace("repeat_statement", "REPEAT statement_list_optional UNTIL (expression)");
        $$ = loopStack.top();
        loopStack.pop();
        $$->exp1 = $5; // expression
        $$->exp2 = $3; // statements
    }
    ;
for_statement:
      KW_FOR IDENTIFIER ASSIGNMENT expression KW_TO expression by_declaration_optional KW_DO {
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::For;
        loopStack.push(node);
    } statement_list_optional KW_END
    {
        // VALIDATION: Variable declaration
        MakeIdentifierNode(@2, $2, identifier);
        // VALIDATOIN: Integer only
        ValidateValueType(@2, identifier->valueType, ValueType::Integer);
        ValidateValueType(@4, $4->valueType, ValueType::Integer);
        ValidateValueType(@6, $6->valueType, ValueType::Integer);
        ValidateValueType(@7, $7->valueType, ValueType::Integer);

        TokenNode* assignNode = new TokenNode(@1);
        assignNode->operatorType = OperatorType::Assign;
        assignNode->exp1 = identifier;
        assignNode->exp2 = $4; // assignment expression

        TokenNode* byNode = new TokenNode(@1);
        byNode->operatorType = OperatorType::Add;
        byNode->valueType = identifier->valueType;
        byNode->exp1 = identifier;
        byNode->exp2 = $7; // by expression

        TokenNode* terminateNode = new TokenNode(@1);
        if (byNode->exp2->value.iValue < 0)
        {
            terminateNode->operatorType = OperatorType::GreaterEqualThen;
        } else {
            terminateNode->operatorType = OperatorType::LessEqualThen;
        }
        terminateNode->valueType = ValueType::Bool;
        terminateNode->exp1 = identifier;
        terminateNode->exp2 = $6; // to expression

        $$ = loopStack.top();
        loopStack.pop();
        $$->exp1 = assignNode;
        $$->exp2 = byNode;
        $$->exp3 = terminateNode;
        $$->exp4 = $10; // statement
    }
    ;    
by_declaration_optional:
      EMPTY
    {
        Trace("by_declaration_optional", "EMPTY");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Integer;
        $$->value.iValue = 1;
    }
    | KW_BY INTEGER
    {
        Trace("by_declaration_optional", "BY INTEGER");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Integer;
        $$->value.iValue = $2;
    }
    | KW_BY IDENTIFIER
    {
        Trace("by_declaration_optional", "BY identifier");
        // VALIDATION: Variable declaration
        MakeIdentifierNode(@2, $2, identifier);
        // VALIDATION: Const
        ValidateEntryType(@2, identifier->symbolTableEntry->entryType, EntryType::Constant);
        // VALIDATION: Integer
        ValidateValueType(@2, identifier->valueType, ValueType::Integer);

        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::ConstValue;
        $$->valueType = ValueType::Integer;
        $$->value.iValue = identifier->symbolTableEntry->value.iValue;
    }
    ;
loop_statement:
      KW_LOOP {
        TokenNode* node = new TokenNode(@1);
        node->operatorType = OperatorType::Loop;
        loopStack.push(node);
    } statement_list_optional KW_END
    {
        $$ = loopStack.top();
        loopStack.pop();
        $$->exp1 = $3;
    }
    ;
continue_exit_statement:
      KW_EXIT
    {
        Trace("continue_exit_statement", "exit");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Exit;

        // VALIDATION: EXIT location
        if (loopStack.empty())
        {
            Warn(@1, "Invalid exit statement placement");
        }
        else
        {
            $$->parent = loopStack.top();
        }
    }
    | KW_CONTINUE
    {
        Trace("continue_exit_statement", "continue");
        $$ = new TokenNode(@1);
        $$->operatorType = OperatorType::Continue;

        // VALIDATION: CONTINUE location
        if (loopStack.empty())
        {
            Warn(@1, "Invalid continue statement placement");
        }
        else
        {
            $$->parent = loopStack.top();
        }
    }
    ;
function_call_statement:
      function_call
    {
        Trace("function_call_statement", "function_call");
        $$ = $1;
    }
    ;

%%

void yy::BisonParser::error(const location_type& loc, const std::string& msg)
{
    std::cout << "line:" << loc << ": ";
    if (msg.find("WARNING:") == 0)
    {
        // Print warning message to stdout
        std::cerr << "\033[33m" << msg << "\033[0m" << std::endl;
    }
    else
    {
        // Print error message to stderr
        std::cerr << "\033[31m" << "ERROR: " << msg << "\033[0m" << std::endl;
    }
}
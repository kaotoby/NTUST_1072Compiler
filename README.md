# NTUST 1072 Compiler Homework

Language: Modula<sup>-</sup>

## Build

Make sure following is installed:
* GCC/G++
* flex (2.6.4)
* bison (3.0.4)
* make
* jre8 / openjkd-8

Building will only work on LINUX system.

On Windows, you'll need to use WSL to build it.

Tested on Ubuntu 18.04 and Windows 10 (WSL Ubuntu 18.04)

To build

```
chmod +x javaa
make clean
make
```

## Usage

```
compiler [options] filename

Options:
    -r    Run the code on jvm after code generation.
    -c    Output comment into .jasm file durning code generation.
    -o    Output node operator type comment into .jasm file durning code generation.
    -n    No jasm code generation.
    -l    Showing each line when lex is parsing tokens.
    -t    Showing lex token information.
    -p    Showing yacc parsing trace.
    -v    Showing all trace information (same as -t -p).
```    
    
## Extra implementation

1. Implement all `String` and `Float` function
2. Implement local and global Array declaration, load and store.
3. Implement `Read` (using java.util.Scanner)
4. Implement `Continue` and `Exit` inside loop statements.
5. Implement `Repeat` `Until` loop
6. Implement `For` loop
7. Implement `Loop` loop


### javaaProtable lexer modification

1. Implement String escaping
2. Implement negative float and double
3. Fixing slash(/) in multiline comment /* */

## Language Definition

### Lexical

#### Delimiters

```
comma ,
colon :
period .
semicolon ;
parentheses ( )
square brackets [ ]
brackets { }
```

#### Arithmetic, Relational, and Logical Operators

```
arithmetic + - * /
remainder %
relational < <= >= > = <>
logical && || ~
assignment :=
```

#### Keywords

`array` `boolean` `begin` `break` `char` `case` `const` `continue` `do` `else` `end` `exit` `false` `for` `fn` `if` `in` `integer` `loop` `module` `print` `println` `procedure` `repeat` `return` `real` `string` `record` `then` `true` `type` `use` `util` `var` `while`

#### Identifiers

An identifier is a string of letters and digits beginning with a letter. Case of letters is relevant, i.e. ident,
Ident, and IDENT are not the same identifier. Note that keywords are not identifiers.

#### Integer Constants

A sequence of one or more digits.

#### Boolean Constants

Either true or false.

#### Real Constants

A sequence of one or more digits containing a decimal point, optinally preceded by a sign (+ or 􀀀), and
optionally following by an exponent letter and exponent.

#### String Constants
A string constant is a sequence of zero or more ASCII characters appearing between double-quote (”)
delimiters. A double-quote appearing with a string must be written after a ”. For example, ”aa” ”bb”
denotes the string constant aa”bb.

#### Comments

Comments can be denoted in several ways:
* Modula-style is text surrounded by “(*” and “*)” delimiters, which may span more than one line;
* C++-style comments are a text following a “//” delimiter running up to the end of the line.

### Syntactic

#### Data Types and Declarations

The predefined data types are `string`, `integer`, `boolean`, and `real`.

#### Constant and Variable Declarations

There are two types of constants and variables in a program:
* global constants and variables: declared inside the program
* local constants and variables: declared inside functions

##### Constants
A constant declaration has the form:
```
const identifier = constant exp; <...; identifier = constant exp; >
```
The type of the declared constant must be inferred based on the constant expression on the right-hand side.
Note that constants cannot be reassigned or this code would cause an error.

For example,
```
const s = "Hey There";
      i = -25;
      f = 3.14;
      b = true;
```

##### Variables
A variable declaration has the form:
```
var identifier<, ... , identifier>: type; <...; identifier<, ... , identifier>: type;>
```
where type is one of the predefined data types. For example,
```
var s : string;
    i : integer;
    d : real;
    b : boolean;
```

##### Arrays
Arrays declaration has the form:
```
identifier<, ... , identifier>: array [num ... num ] of type;
...;
identifier<, ... , identifier>: array [num ... num ] of type;
```
For example,
```
a: array [1, 10] of integer; // an array of 10 integer elements
b: array [0, 5] of boolean; // an array of 6 boolean elements
f: array [1, 100] of real; // an array of 100 float-point elements
```

#### Program Units
The two program units are the program and functions.

##### Program
A program has the form:
```
module identifier
<zero or more variable and constant declarations>
<zero or more function declarations>
begin
<zero or more statements>
end identifier.
```
where the item in the < > pair is optional.

##### Procedures
Procedure declaration has the following form:
```
procedure identifier <( formal arguments )> <: type >
<zero or more constant and anvariable declarations>
begin
<one or more statements>
end identifier;
```
where : type is optional and type can be one of the predefined types. The formal arguments are declared in the following form:
```
identifier : type <, identifier : type, ... , identifier : type>
```
Parentheses are not required when no arguments are declared. No procedures may be declared inside a procedure. For example,
```
module example
// constants and variables
const a = 5;
var c : integer;
// procedure declaration
procedure add(a:integer, b:integer) : integer
begin
    return a+b;
end add;
// statements
begin
    c = add(a, 10);
    print c;
end example.
```

#### Statements
There are several distinct types of statements in Modula􀀀.

##### Simple
The simple statement has the form:
```
identifier := expression;
```
or
```
identifier[integer expression] := expression;
```
or
```
print expression; or println expression;
```
or
```
read identifier;
```
or
```
return; or return expression;
```

##### Expressions
Arithmetic expressions are written in infix notation, using the following operators with the precedence:
```
(1) - (unary)
(2) * /
(3) + -
(4) < <= = => > <>
(5) ~
(6) &&
(7) ||
```
Associativity is the left. Valid components of an expression include literal constants, variable names, function
invocations, and array reference of the form
```
A [ integer expression ]
```

##### Function invocation
A function invocation has the following form:
```
identifier ( <comma-separated expressions> )
```

##### Conditional
The conditional statement may appear in two forms:
```
if (boolean expr) then
<zero or more statements>
else
<zero or more statements>
end;
```
or
```
if (boolean expr) then
<zero or more statements>
end;
```

##### Loop
The loop statement has the form:
```
while (boolean expr) do
<zero or more statements>
end ;
```

### Semantic Definition
The semantics of the constructs are the same as the corresponding Pascal and C constructs, with the following
exceptions and notes:
* The parameter passing mechanism for procedures in call-by-value.
* Scope rules are similar to C.
* The identifier after the end of program or procedure declaration must be the same identifiers as the name given at the beginning of the declaration.
* Types of the left-hand-side identifier and the right-hand-side expression of every assignment must be matched.
* The types of formal parameters must match the types of the actual parameters.

/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#ifndef TOKEN_NODE_H
#define TOKEN_NODE_H

#include <string>
#include "location.hh"
#include "symbol_table.h"
#include "driver.h"

#ifndef GLOBAL_SYM_TABLE_NAME
#define GLOBAL_SYM_TABLE_NAME "_global"
#endif


namespace yy
{
class TokenNode
{
public:
    TokenNode(location loc);

    OperatorType operatorType;
    ValueType valueType;
    unsigned int lineNumber;

    // For ConstValue operation
    Value value;
    // For IdentifierValue, FunctionInvoke, ArrayIndex, FunctionDeclaration operation
    SymbolTableEntry *symbolTableEntry;
    // For Statement, ElseIf, FunctionArgument
    TokenNode *last;
    TokenNode *next;
    // For ElseIf, Exit, Continue
    TokenNode *parent;
    // For all others
    TokenNode *exp1;
    TokenNode *exp2;
    TokenNode *exp3;
    TokenNode *exp4;
};

} // namespace yy

#endif
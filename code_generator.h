/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#ifndef CODE_GENERATOR_H
#define CODE_GENERATOR_H

#include <fstream>
#include <map>
#include <string>
#include "token_node.h"

#define JASM_MAX_STACK 15

class CodeGenerator
{
public:
    CodeGenerator(std::ofstream* output, std::map<std::string, SymbolTable*> &symbolTableMap, std::vector<std::string> &sourceLines, bool outputComment, bool outputOperatorType);

    // Generate jasm file using specific TokneNode
    void GenerateJasm(TokenNode* programNode);
private:
    std::ofstream* output;
    std::map<std::string, SymbolTable*> &symbolTableMap;
    std::vector<std::string> sourceLines;
    std::string className;
    int labelCounter;
    int currentLine = 0;
    bool outputComment;
    bool outputOperatorType;

    // Value type to java string
    std::string ValueTypeToString(yy::ValueType valueType);
    // Get unique label
    std::string GetNewLabel();
    // Value to local const command
    std::string ValueToLocalConstCommand(ValueType valueType, Value value);
    // Value to local variable command
    std::string ValueToLocalVariableCommand(ValueType valueType, int id);
    // Value to local variable command
    std::string ArrayValueToLocalVariableCommand(ValueType valueType, int id);
    // Symbol table entry to assign command
    std::string EntryToAssignCommand(SymbolTableEntry* entry);
};


#endif
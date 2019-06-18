/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#include "code_generator.h"
#include <iostream>
#include <iomanip>

using namespace std;
using namespace yy;

CodeGenerator::CodeGenerator(std::ofstream *output_arg, map<string, SymbolTable *> &symbolTableMap_arg, vector<string> &sourceLines_arg, bool outputComment, bool outputOperatorType)
    : output(output_arg), symbolTableMap(symbolTableMap_arg), sourceLines(sourceLines_arg)
{
    this->labelCounter = 0;
    this->outputComment = outputComment;
    this->outputOperatorType = outputOperatorType;
    this->currentLine = 0;
    *output << "/*-------------------------------------------------*/" << endl;
    *output << "/*               Java Assembly Code                */" << endl;
    *output << "/*-------------------------------------------------*/" << endl;
}

void CodeGenerator::GenerateJasm(TokenNode *node)
{
    if (node == NULL)
    {
        return;
    }
    if (this->outputComment)
    {
        for (this->currentLine; this->currentLine < node->lineNumber; this->currentLine++)
        {
            *output << "/* " << right << setw(4)
                    << to_string(this->currentLine + 1) + ":"
                    << " " << this->sourceLines[this->currentLine] << " */" << endl;
        }
    }
    if (this->outputOperatorType)
    {
        *output << "/* " << EnumToString(node->operatorType) << " */" << endl;
    }
    // Process
    switch (node->operatorType)
    {
    case OperatorType::Program:
    {
        vector<SymbolTableEntry *> arrayEntry;
        this->className = node->symbolTableEntry->name;
        *output << "class " << this->className << endl;
        *output << "{" << endl;
        // Static variables
        vector<SymbolTableEntry *> variableTable = symbolTableMap[GLOBAL_SYM_TABLE_NAME]->GetVariableTable();
        for (int i = 0; i < variableTable.size(); i++)
        {
            if (variableTable[i]->valueType == ValueType::Array)
            {
                *output << "    field static " << ValueTypeToString(variableTable[i]->arrayEntry.valueType) << "[] " << variableTable[i]->name << endl;
                arrayEntry.push_back(variableTable[i]);
            }
            else
            {
                *output << "    field static " << ValueTypeToString(variableTable[i]->valueType) << " " << variableTable[i]->name << endl;
            }
        }
        // function_declarations
        GenerateJasm(node->exp1);
        *output << "    method public static void main(java.lang.String[])" << endl;
        *output << "    max_stack " << JASM_MAX_STACK << endl;
        int size = symbolTableMap[GLOBAL_SYM_TABLE_NAME]->GetVariableTable().size();
        if (size > 0)
        {
            *output << "    max_locals " << size << endl;
        }
        *output << "    {" << endl;
        // static array init
        for (int i = 0; i < arrayEntry.size(); i++)
        {
            int arraySize = arrayEntry[i]->arrayEntry.high - arrayEntry[i]->arrayEntry.low + 1;
            *output << "        bipush " << arraySize << endl;
            if (arrayEntry[i]->arrayEntry.valueType == ValueType::String)
            {
                *output << "        anewarray java.lang.String" << endl;
            }
            else
            {
                *output << "        newarray " << ValueTypeToString(arrayEntry[i]->arrayEntry.valueType) << endl;
            }
            *output << "        putstatic " << ValueTypeToString(arrayEntry[i]->arrayEntry.valueType) << "[] " << this->className << "." << arrayEntry[i]->name << endl;
        }
        // statements
        GenerateJasm(node->exp2);
        *output << "        return" << endl;
        *output << "    }" << endl;
        *output << "}" << endl;
    }
    break;
    case OperatorType::FunctionDeclaration:
    {
        string scope = node->symbolTableEntry->name;
        *output << "    method public static " << ValueTypeToString(node->symbolTableEntry->valueType) << " " << scope << "(";
        vector<SymbolTableEntry *> argumentTable = symbolTableMap[scope]->GetArgumentTable();
        for (int i = 0; i < argumentTable.size(); i++)
        {
            if (i > 0)
            {
                *output << ", ";
            }
            *output << ValueTypeToString(argumentTable[i]->valueType);
        }
        *output << ")" << endl;
        *output << "    max_stack " << JASM_MAX_STACK << endl;
        vector<SymbolTableEntry *> variableTable = symbolTableMap[scope]->GetVariableTable();
        if (variableTable.size() > 0)
        {
            *output << "    max_locals " << variableTable.size() << endl;
        }
        *output << "    {" << endl;
        // init local arrays
        for (int i = 0; i < variableTable.size(); i++)
        {
            if (variableTable[i]->valueType == ValueType::Array)
            {
                int arraySize = variableTable[i]->arrayEntry.high - variableTable[i]->arrayEntry.low + 1;
                *output << "        bipush " << arraySize << endl;
                if (variableTable[i]->arrayEntry.valueType == ValueType::String)
                {
                    *output << "        anewarray java.lang.String" << endl;
                }
                else
                {
                    *output << "        newarray " << ValueTypeToString(variableTable[i]->arrayEntry.valueType) << endl;
                }
                *output << "        astore " << variableTable[i]->value.iValue << endl;
            }
        }
        // statements
        GenerateJasm(node->exp1);
        if (node->symbolTableEntry->valueType == ValueType::Void)
        {
            *output << "        return" << endl;
        }
        *output << "    }" << endl;
        // next declaration
        GenerateJasm(node->next);
    }
    break;
    case OperatorType::FunctionInvoke:
    {
        // function argument
        GenerateJasm(node->exp2);
        string scope = node->symbolTableEntry->name;
        *output << "        invokestatic " << ValueTypeToString(node->valueType) << " " << this->className << "." << scope << "(";
        vector<SymbolTableEntry *> argumentTable = symbolTableMap[scope]->GetArgumentTable();
        for (int i = 0; i < argumentTable.size(); i++)
        {
            if (i > 0)
            {
                *output << ", ";
            }
            *output << ValueTypeToString(argumentTable[i]->valueType);
        }
        *output << ")" << endl;
    }
    break;
    case OperatorType::FunctionArgument:
    {
        // expression
        GenerateJasm(node->exp1);
        // next expression
        GenerateJasm(node->next);
    }
    break;
    case OperatorType::Statement:
    {
        // expression
        GenerateJasm(node->exp1);
        // next statement
        GenerateJasm(node->next);
    }
    break;
    case OperatorType::ConstValue:
    {
        *output << ValueToLocalConstCommand(node->valueType, node->value) << endl;
    }
    break;
    case OperatorType::IdentifierValue:
    {
        switch (node->symbolTableEntry->entryType)
        {
        case EntryType::Argument:
            *output << "        " << ValueToLocalVariableCommand(node->valueType, node->symbolTableEntry->value.iValue) << endl;
            break;
        case EntryType::Variable:
            if (node->symbolTableEntry->symbolTable->scope == GLOBAL_SYM_TABLE_NAME)
            {
                // global
                if (node->valueType == ValueType::Array)
                {
                    *output << "        getstatic " << ValueTypeToString(node->symbolTableEntry->arrayEntry.valueType) << "[] " << this->className << "." << node->symbolTableEntry->name << endl;
                }
                else
                {
                    *output << "        getstatic " << ValueTypeToString(node->valueType) << " " << this->className << "." << node->symbolTableEntry->name << endl;
                }
            }
            else
            {
                // local
                *output << "        " << ValueToLocalVariableCommand(node->valueType, node->symbolTableEntry->value.iValue) << endl;
            }
            break;
        case EntryType::Constant:
            *output << ValueToLocalConstCommand(node->valueType, node->symbolTableEntry->value) << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Return:
    {
        if (node->valueType == ValueType::Void)
        {
            *output << "        return" << endl;
        }
        else
        {
            // expression
            GenerateJasm(node->exp1);
            switch (node->valueType)
            {
            case ValueType::Integer:
            case ValueType::Bool:
                *output << "        ireturn" << endl;
                break;
            case ValueType::Float:
                *output << "        freturn" << endl;
                break;
            case ValueType::String:
                *output << "        areturn" << endl;
                break;
            default:
                break;
            }
        }
    }
    break;
    case OperatorType::Assign:
    {
        if (node->exp1->operatorType == OperatorType::ArrayStore)
        {
            // push array to stack
            GenerateJasm(node->exp1);
        }
        // expression
        GenerateJasm(node->exp2);
        // assignment
        *output << "        " << EntryToAssignCommand(node->exp1->symbolTableEntry) << endl;
    }
    break;
    /* Arithmetic operation */
    case OperatorType::Add:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        iadd" << endl;
            break;
        case ValueType::Float:
            *output << "        fadd" << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Minus:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        isub" << endl;
            break;
        case ValueType::Float:
            *output << "        fsub" << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Multiply:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        imul" << endl;
            break;
        case ValueType::Float:
            *output << "        fmul" << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Devide:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        idiv" << endl;
            break;
        case ValueType::Float:
            *output << "        fdiv" << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Reminder:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        irem" << endl;
            break;
        case ValueType::Float:
            *output << "        frem" << endl;
            break;
        default:
            break;
        }
    }
    break;
    case OperatorType::Negative:
    {
        // expression
        GenerateJasm(node->exp1);
        // operation
        switch (node->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            *output << "        ineg" << endl;
            break;
        case ValueType::Float:
            *output << "        fneg" << endl;
            break;
        default:
            break;
        }
    }
    break;
    /* Relational operation */
    case OperatorType::LessThen:
    case OperatorType::LessEqualThen:
    case OperatorType::GreaterThen:
    case OperatorType::GreaterEqualThen:
    case OperatorType::Equal:
    case OperatorType::NotEqual:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        // condition
        string label = GetNewLabel();
        string l0 = label + "_False";
        string l1 = label + "_True";
        switch (node->exp1->valueType)
        {
        case ValueType::Integer:
            *output << "        isub" << endl;
            break;
        case ValueType::Float:
            switch (node->operatorType)
            {
            case OperatorType::LessThen:
            case OperatorType::LessEqualThen:
            case OperatorType::GreaterThen:
            case OperatorType::GreaterEqualThen:
                *output << "        fcmpg " << endl;
                break;
            case OperatorType::Equal:
            case OperatorType::NotEqual:
                *output << "        fcmpl " << endl;
                break;
            }
            break;
        default:
            break;
        }
        switch (node->operatorType)
        {
        case OperatorType::LessThen:
            *output << "        iflt " << l1 << endl;
            break;
        case OperatorType::LessEqualThen:
            *output << "        ifle " << l1 << endl;
            break;
        case OperatorType::GreaterThen:
            *output << "        ifgt " << l1 << endl;
            break;
        case OperatorType::GreaterEqualThen:
            *output << "        ifge " << l1 << endl;
            break;
        case OperatorType::Equal:
            *output << "        ifeq " << l1 << endl;
            break;
        case OperatorType::NotEqual:
            *output << "        ifne " << l1 << endl;
            break;
        }
        *output << "        iconst_0" << endl;
        *output << "        goto " << l0 << endl;
        *output << l1 + ": " << endl;
        *output << "        iconst_1" << endl;
        *output << l0 << ":" << endl;
    }
    break;
    /* Logical operation */
    case OperatorType::LogicalAnd:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        *output << "        iand" << endl;
    }
    break;
    case OperatorType::LogicalOr:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        *output << "        ior" << endl;
    }
    break;
    case OperatorType::LogicalNot:
    {
        // expression
        GenerateJasm(node->exp1);
        GenerateJasm(node->exp2);
        *output << "        ixor" << endl;
    }
    break;
    /* Conditional operation */
    case OperatorType::If:
    {
        // label
        string label = GetNewLabel();
        string lelse = label + "_Else";
        string lexit = label + "_IfExit";
        node->value.sValue = lexit.c_str();
        // condition expression
        GenerateJasm(node->exp1);
        // condition branch
        *output << "        ifeq " << lelse << endl;
        GenerateJasm(node->exp2);
        *output << "        goto " << lexit << endl;
        *output << lelse << ":" << endl;
        // elseif
        GenerateJasm(node->next);
        // else
        if (node->exp3 == NULL)
        {
            *output << "        nop" << endl;
        }
        else
        {
            GenerateJasm(node->exp3);
        }
        // exit
        *output << lexit << ":" << endl;
        *output << "        nop" << endl;
    }
    break;
    case OperatorType::ElseIf:
    {
        // label
        string lelse = GetNewLabel() + "_Else";
        string lexit = node->parent->value.sValue;
        // condition expression
        GenerateJasm(node->exp1);
        // condition branch
        *output << "        ifeq " << lelse << endl;
        GenerateJasm(node->exp2);
        *output << "        goto " << lexit << endl;
        *output << lelse << ":" << endl;
        // Next else if
        GenerateJasm(node->next);
    }
    break;
    case OperatorType::While:
    {
        // label
        string label = GetNewLabel() + "_While";
        string lbegin = label + "Begin";
        string lexit = label + "Exit";
        node->value.sValue = label.c_str();
        *output << lbegin << ":" << endl;
        // condition
        GenerateJasm(node->exp1);
        *output << "        ifeq " << lexit << endl;
        // statement
        GenerateJasm(node->exp2);
        *output << "        goto " << lbegin << endl;
        // exit
        *output << lexit << ":" << endl;
        *output << "        nop" << endl;
    }
    break;
    case OperatorType::Repeat:
    {
        // label
        string label = GetNewLabel() + "_Repeat";
        string lbegin = label + "Begin";
        string lexit = label + "Exit";
        node->value.sValue = label.c_str();
        *output << lbegin << ":" << endl;
        // statement
        GenerateJasm(node->exp2);
        // condition
        GenerateJasm(node->exp1);
        *output << "        ifne " << lexit << endl;
        *output << "        goto " << lbegin << endl;
        // exit
        *output << lexit << ":" << endl;
        *output << "        nop" << endl;
    }
    break;
    case OperatorType::For:
    {
        // label
        string label = GetNewLabel() + "_For";
        string lbegin = label + "Begin";
        string lcontinue = label + "Continue";
        string lexit = label + "Exit";
        node->value.sValue = label.c_str();
        // initialize
        GenerateJasm(node->exp1);
        *output << lbegin << ":" << endl;
        // condition
        GenerateJasm(node->exp3);
        *output << "        ifeq " << lexit << endl;
        // statement
        GenerateJasm(node->exp4);

        *output << lcontinue << ":" << endl;
        //// for node -> assignment node -> array index node
        if (node->exp1->exp1->operatorType == OperatorType::ArrayStore)
        {
            // push array to stack
            GenerateJasm(node->exp1->exp1);
        }
        // increment
        GenerateJasm(node->exp2);
        // for node -> assignment node -> id node
        *output << "        " << EntryToAssignCommand(node->exp1->exp1->symbolTableEntry) << endl;
        *output << "        goto " << lbegin << endl;
        // exit
        *output << lexit << ":" << endl;
        *output << "        nop" << endl;
    }
    break;
    case OperatorType::Loop:
    {
        // label
        string label = GetNewLabel() + "_Loop";
        string lbegin = label + "Begin";
        string lexit = label + "Exit";
        node->value.sValue = label.c_str();
        // statement
        *output << lbegin << ":" << endl;
        GenerateJasm(node->exp1);
        *output << "        goto " << lbegin << endl;
        // exit
        *output << lexit << ":" << endl;
        *output << "        nop" << endl;
    }
    break;
    case OperatorType::Continue:
    {
        string lbegin = node->parent->value.sValue;
        if (node->parent->operatorType == OperatorType::For)
        {
            lbegin += "Continue";
        }
        else
        {
            lbegin += "Begin";
        }
        *output << "        goto " << lbegin << endl;
    }
    break;
    case OperatorType::Exit:
    {
        string lexit = string(node->parent->value.sValue) + "Exit";
        *output << "        goto " << lexit << endl;
    }
    break;
    /* Speical functions */
    case OperatorType::Read:
    {
        if (node->exp1->operatorType == OperatorType::ArrayStore)
        {
            // push array to stack
            GenerateJasm(node->exp1);
        }
        *output << "        new java.util.Scanner" << endl;
        *output << "        dup" << endl;
        *output << "        getstatic java.io.InputStream java.lang.System.in" << endl;
        *output << "        invokenonvirtual void java.util.Scanner.<init>(java.io.InputStream)" << endl;
        switch (node->exp1->valueType)
        {
        case ValueType::Integer:
            *output << "        invokevirtual int java.util.Scanner.nextInt()" << endl;
            break;
        case ValueType::Float:
            *output << "        invokevirtual float java.util.Scanner.nextFloat()" << endl;
            break;
        case ValueType::Bool:
            *output << "        invokevirtual boolean java.util.Scanner.nextBoolean()" << endl;
            break;
        case ValueType::String:
            *output << "        invokevirtual java.lang.String java.util.Scanner.next()" << endl;
            break;
        default:
            *output << "        pop" << endl;
            *output << "        pop" << endl;
        }
        // assignment
        *output << "        " << EntryToAssignCommand(node->exp1->symbolTableEntry) << endl;
    }
    break;
    case OperatorType::Print:
    {
        *output << "        getstatic java.io.PrintStream java.lang.System.out" << endl;
        // expression
        GenerateJasm(node->exp1);
        *output << "        invokevirtual void java.io.PrintStream.print(" << ValueTypeToString(node->exp1->valueType);
        *output << ")" << endl;
    }
    break;
    case OperatorType::PrintLine:
    {
        *output << "        getstatic java.io.PrintStream java.lang.System.out" << endl;
        // expression
        GenerateJasm(node->exp1);
        *output << "        invokevirtual void java.io.PrintStream.println(" << ValueTypeToString(node->exp1->valueType);
        *output << ")" << endl;
    }
    break;
    /* Array */
    case OperatorType::ArrayLoad:
    {
        // array
        GenerateJasm(node->exp1);
        // expression
        GenerateJasm(node->exp2);
        if (node->symbolTableEntry->arrayEntry.low != 0)
        {
            *output << "        sipush " << node->symbolTableEntry->arrayEntry.low << endl;
            *output << "        isub" << endl;
        }
        switch (node->valueType)
        {
        case ValueType::Integer:
            *output << "        iaload";
            break;
        case ValueType::Bool:
            *output << "        baload";
            break;
        case ValueType::Float:
            *output << "        faload";
            break;
        case ValueType::String:
        case ValueType::Array:
            *output << "        aaload";
            break;
        default:
            *output << "        pop" << endl;
            break;
        }
    }
    break;
    case OperatorType::ArrayStore:
    {
        // array
        GenerateJasm(node->exp1);
        // expression
        GenerateJasm(node->exp2);
        if (node->symbolTableEntry->arrayEntry.low != 0)
        {
            *output << "        sipush " << node->symbolTableEntry->arrayEntry.low << endl;
            *output << "        isub" << endl;
        }
    }
    break;
    default:
        break;
    }
}

string CodeGenerator::ValueTypeToString(ValueType valueType)
{
    switch (valueType)
    {
    case ValueType::Void:
        return "void";
    case ValueType::Integer:
        return "int";
    case ValueType::Float:
        return "float";
    case ValueType::Bool:
        return "boolean";
    case ValueType::String:
        return "java.lang.String";
    default:
        return "";
        break;
    }
}

string CodeGenerator::GetNewLabel()
{
    return "L" + to_string(this->labelCounter++);
}

string CodeGenerator::ValueToLocalConstCommand(ValueType valueType, Value value)
{
    switch (valueType)
    {
    case ValueType::Integer:
        return "        sipush " + to_string(value.iValue);
    case ValueType::Float:
        return "        ldc " + to_string(value.fValue) + "f";
    case ValueType::Bool:
        return string("        ") + (value.bValue ? "iconst_1" : "iconst_0");
    case ValueType::String:
    {

        string str = value.sValue;
        string cmd = "        ldc \"";
        for (int i = 0; i < str.length(); i++)
        {
            if (str[i] == '"')
            {
                cmd += "\\\"";
            }
            else
            {
                cmd += str[i];
            }
        }
        cmd += "\"";
        return cmd;
    }
    default:
        return "";
    }
}

string CodeGenerator::ValueToLocalVariableCommand(ValueType valueType, int id)
{
    switch (valueType)
    {
    case ValueType::Integer:
    case ValueType::Bool:
        return "iload " + to_string(id);
    case ValueType::Float:
        return "fload " + to_string(id);
    case ValueType::String:
    case ValueType::Array:
        return "aload " + to_string(id);
    default:
        return "";
    }
}

string CodeGenerator::EntryToAssignCommand(SymbolTableEntry *entry)
{
    if (entry->valueType == ValueType::Array)
    {
        switch (entry->arrayEntry.valueType)
        {
        case ValueType::Integer:
            return "iastore";
        case ValueType::Bool:
            return "bastore";
        case ValueType::Float:
            return "fastore ";
        case ValueType::String:
            return "aastore ";
        default:
            return "pop";
        }
    }
    else if (entry->symbolTable->scope == GLOBAL_SYM_TABLE_NAME)
    {
        // global
        return "putstatic " + ValueTypeToString(entry->valueType) + " " + this->className + "." + entry->name;
    }
    else
    {
        // local
        switch (entry->valueType)
        {
        case ValueType::Integer:
        case ValueType::Bool:
            return "istore " + to_string(entry->value.iValue);
        case ValueType::Float:
            return "fstore " + to_string(entry->value.iValue);
        case ValueType::String:
            return "astore " + to_string(entry->value.iValue);
        default:
            return "pop";
        }
    }
}
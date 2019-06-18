/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#ifndef DRIVER_H
#define DRIVER_H

#include <string>

namespace yy
{
// 值
union Value {
    int iValue;
    float fValue;
    const char *sValue;
    bool bValue;
};
// 值類型列舉
enum ValueType
{
    Void = 0,
    Integer = 1,
    Float = 2,
    Bool = 3,
    String = 4,
    Array = 5,
};
// 項目類型列舉
enum EntryType
{
    Constant = 0,
    Variable = 1,
    Argument = 2,
    Function = 3
};
// 操作列舉
enum OperatorType
{
    // system operation
    Program = 0,
    FunctionDeclaration = 1,
    FunctionInvoke = 2,
    FunctionArgument = 3,
    Statement = 4,
    ConstValue = 5,
    IdentifierValue = 6,
    Return = 7,
    Assign = 8,
    // arithmetic
    Add = 10,
    Minus = 11,
    Multiply = 12,
    Devide = 13,
    Reminder = 14,
    Negative = 15,
    // relational
    LessThen = 20,
    LessEqualThen = 21,
    GreaterThen = 22,
    GreaterEqualThen = 23,
    Equal = 24,
    NotEqual = 25,
    // logical
    LogicalAnd = 30,
    LogicalOr = 31,
    LogicalNot = 32,
    // condition
    If = 40,
    ElseIf = 41,
    While = 42,
    Repeat = 43,
    For = 44,
    Loop = 45,
    Continue = 46,
    Exit = 47,
    // special function
    Read = 50,
    Print = 51,
    PrintLine = 52,
    // array
    ArrayLoad = 60,
    ArrayStore = 61,
};

inline std::string EnumToString(const ValueType value)
{
    switch (value)
    {
    case ValueType::Void:
        return "void";
    case ValueType::Integer:
        return "integer";
    case ValueType::Float:
        return "real";
    case ValueType::Bool:
        return "boolean";
    case ValueType::String:
        return "string";
    case ValueType::Array:
        return "array";
    default:
        return std::to_string(value);
    }
}

inline std::string EnumToString(const EntryType value)
{
    switch (value)
    {
    case EntryType::Constant:
        return "const";
    case EntryType::Variable:
        return "var";
    case EntryType::Argument:
        return "arg";
    case EntryType::Function:
        return "func";
    default:
        return std::to_string(value);
    }
}

inline std::string EnumToString(const OperatorType value)
{
    switch (value)
    {
    case OperatorType::Program:
        return "Program";
    case OperatorType::FunctionDeclaration:
        return "FunctionDeclaration";
    case OperatorType::FunctionInvoke:
        return "FunctionInvoke";
    case OperatorType::FunctionArgument:
        return "FunctionArgument";
    case OperatorType::Statement:
        return "Statement";
    case OperatorType::ConstValue:
        return "ConstValue";
    case OperatorType::IdentifierValue:
        return "IdentifierValue";
    case OperatorType::Return:
        return "Return";
    case OperatorType::Assign:
        return "Assign";

    case OperatorType::Add:
        return "Add";
    case OperatorType::Minus:
        return "Minus";
    case OperatorType::Multiply:
        return "Multiply";
    case OperatorType::Devide:
        return "Devide";
    case OperatorType::Reminder:
        return "Reminder";
    case OperatorType::Negative:
        return "Negative";

    case OperatorType::LessThen:
        return "LessThen";
    case OperatorType::LessEqualThen:
        return "LessEqualThen";
    case OperatorType::GreaterThen:
        return "GreaterThen";
    case OperatorType::GreaterEqualThen:
        return "GreaterEqualThen";
    case OperatorType::Equal:
        return "Equal";
    case OperatorType::NotEqual:
        return "NotEqual";

    case OperatorType::LogicalAnd:
        return "LogicalAnd";
    case OperatorType::LogicalOr:
        return "LogicalOr";
    case OperatorType::LogicalNot:
        return "LogicalNot";

    case OperatorType::If:
        return "If";
    case OperatorType::ElseIf:
        return "ElseIf";
    case OperatorType::While:
        return "While";
    case OperatorType::Repeat:
        return "Repeat";
    case OperatorType::For:
        return "For";
    case OperatorType::Loop:
        return "Loop";
    case OperatorType::Continue:
        return "Continue";
    case OperatorType::Exit:
        return "Exit";

    case OperatorType::Read:
        return "Read";
    case OperatorType::Print:
        return "Print";
    case OperatorType::PrintLine:
        return "PrintLine ";

    case OperatorType::ArrayLoad:
        return "ArrayLoad";
    case OperatorType::ArrayStore:
        return "ArrayStore";

    default:
        return std::to_string(value);
    }
}
} // namespace yy

#endif
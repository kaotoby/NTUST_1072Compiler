/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#include "symbol_table.h"
#include <iostream>
#include <iomanip>

using namespace std;

SymbolTable::SymbolTable(const string scope)
{
    this->scope = scope;
}

// 取得資料
SymbolTableEntry *SymbolTable::Find(const string key)
{
    return this->symbolTable[key];
}

// 加入資料
void SymbolTable::Add(const string key, SymbolTableEntry *entry)
{
    entry->symbolTable = this;
    this->symbolTable[key] = entry;
    if (entry->entryType == EntryType::Argument)
    {
        this->argumentTable.push_back(entry);
        entry->value.iValue = this->variableTable.size();
        this->variableTable.push_back(entry);
    }
    else if (entry->entryType == EntryType::Variable)
    {
        entry->value.iValue = this->variableTable.size();
        this->variableTable.push_back(entry);
    }
}

// 判斷是否有指定的 Key
bool SymbolTable::HasKey(const string key)
{
    map<string, SymbolTableEntry *>::iterator it = this->symbolTable.find(key);
    return it != this->symbolTable.end();
}

// 輸出到 stdout
void SymbolTable::Dump()
{
    cout << endl;
    cout << "---------------------------------------------------------" << endl;
    cout << "Dumping symobl table: " << this->scope << endl;
    cout << "---------------------------------------------------------" << endl;
    for (map<string, SymbolTableEntry *>::iterator it = this->symbolTable.begin(); it != this->symbolTable.end(); ++it)
    {
        string entryType = yy::EnumToString(it->second->entryType);

        if (it->second->entryType == yy::EntryType::Argument)
        {
            entryType += to_string(it->second->value.iValue);
        }

        cout << left << setw(5) << entryType << " ";

        string valueType = yy::EnumToString(it->second->valueType);

        if (it->second->valueType == yy::ValueType::Array)
        {
            valueType += ":" + yy::EnumToString(it->second->arrayEntry.valueType);
            valueType += "(" + to_string(it->second->arrayEntry.low) + "," + to_string(it->second->arrayEntry.high) + ")";
        }
        cout << setw(19) << valueType << " " << setw(10) << it->first;

        if (it->second->entryType == yy::EntryType::Constant)
        {
            switch (it->second->valueType)
            {
            case yy::ValueType::Integer:
                cout << " " << it->second->value.iValue;
                break;
            case yy::ValueType::Float:
                cout << " " << it->second->value.fValue;
                break;
            case yy::ValueType::Bool:
                cout << " " << it->second->value.bValue ? "true" : "false";
                break;
            case yy::ValueType::String:
                cout << " \"" << it->second->value.sValue << "\"";
                break;
            }
        }
        cout << endl;
    }
    cout << "---------------------------------------------------------" << endl;
    cout << endl;
}

vector<SymbolTableEntry *> &SymbolTable::GetArgumentTable()
{
    return argumentTable;
}

vector<SymbolTableEntry *> &SymbolTable::GetVariableTable()
{
    return variableTable;
}

map<string, SymbolTableEntry *> &SymbolTable::GetRawSymbolTable()
{
    return symbolTable;
}
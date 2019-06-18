/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <string>
#include <map>
#include <vector>
#include "driver.h"

using namespace yy;
class SymbolTable;

// Symbol table 項目
struct SymbolTableEntry {
    struct ArrayEntry {
        // 值類型
        ValueType valueType;
        int low;
        int high;
    };

    // 值類型
    ValueType valueType;
    // 陣列資料
    struct ArrayEntry arrayEntry;
    // 項目類型
    EntryType entryType;
    // Symbol table 指標
    SymbolTable* symbolTable;
    // 名稱
    std::string name;
    // 值
    Value value;
};
typedef struct SymbolTableEntry SymbolTableEntry;

typedef struct SymbolTableEntry::ArrayEntry ArrayEntry;

class SymbolTable
{
public:
    SymbolTable(const std::string str);

    // 取得資料
    SymbolTableEntry* Find(const std::string key);
    // 加入資料
    void Add(const std::string key, SymbolTableEntry* entry);
    // 判斷是否有指定的 Key
    bool HasKey (const std::string key);
    // 輸出到 stdout
    void Dump();
    // 取得表中參數
    std::vector<SymbolTableEntry*>& GetArgumentTable();
    // 取得表中變數 (包含參數)
    std::vector<SymbolTableEntry*>& GetVariableTable();
    // 取得原始資料表
    std::map<std::string, SymbolTableEntry*>& GetRawSymbolTable();

    // 名稱
    std::string scope;
private:
    // SymbolTable 資料處存
    std::map<std::string, SymbolTableEntry*> symbolTable;
    // 參數表
    std::vector<SymbolTableEntry*> argumentTable;
    // 變數表(包含參數)
    std::vector<SymbolTableEntry*> variableTable;
};

#endif // SYMBOL_TABLE_H
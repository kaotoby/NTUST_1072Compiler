/*
 * Project 3
 * Author: B10630221 Chang-Ting Kao
 * Date: 2019/06/05
 */

#include <fstream>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>
#include "lex.yy.hh"
#include "y.tab.hh"
#include "symbol_table.h"
#include "token_node.h"
#include "code_generator.h"

using namespace std;
using namespace yy;

void printUsage()
{
    cout << "Usage:" << endl;
    cout << "parser [option] filename" << endl;
    cout << endl;
    cout << "Options:" << endl;
    cout << "    -r    Run the code on jvm after code generation." << endl;
    cout << "    -c    Output comment into .jasm file durning code generation." << endl;
    cout << "    -o    Output node operator type comment into .jasm file durning code generation." << endl;
    cout << "    -n    No code generation." << endl;
    cout << "    -l    Showing each line when lex is parsing tokens." << endl;
    cout << "    -t    Showing lex token information." << endl;
    cout << "    -p    Showing yacc parsing trace." << endl;
    cout << "    -v    Showing all trace information (same as -t -p)." << endl;
    exit(-1);
}

string getFileNameWithoutExt(string path)
{
    string str = path;
    int pos = str.find_last_of('/');
    if (pos != string::npos)
    {
        str = str.substr(pos + 1, str.length() - pos);
    }
    return str.substr(0, str.find_last_of("."));
}

int main(int argc, char **argv)
{
    std::ifstream inputFile;
    FlexScanner *scanner;
    BisonParser *parser;
    char *filename = NULL;
    vector<string> sourceLines;

    /* Options */
    bool showToken = false;
    bool showParsing = false;
    bool showLine = false;
    bool doCodeGeneration = true;
    bool outputComment = false;
    bool outputOperatorType = false;
    bool runCode = false;

    if (argc < 2)
    {
        cout << "Error: Input file not specific." << endl;
        printUsage();
    }

    for (int i = 1; i < argc - 1; i++)
    {
        string arg(argv[i]);
        if (arg[0] == '-')
        {
            switch (arg[1])
            {
            case 'l':
                showLine = true;
                break;
            case 'v':
                showToken = true;
                showParsing = true;
                break;
            case 't':
                showToken = true;
                break;
            case 'p':
                showParsing = true;
                break;
            case 'n':
                doCodeGeneration = false;
                break;
            case 'c':
                outputComment = true;
                break;
            case 'o':
                outputOperatorType = true;
                break;
            case 'r':
                runCode = true;
                break;
            default:
                cout << "Invalid argument:" << arg << endl;
                printUsage();
                break;
            }
        }
        else
        {
            cout << "Invalid argument:" << arg << endl;
            printUsage();
        }
    }

    string inFileName = argv[argc - 1];
    // Read source code line by line
    std::ifstream sourceFile(inFileName);
    string sourceLine;
    while (std::getline(sourceFile, sourceLine))
    {
        sourceLines.push_back(sourceLine);
    }
    sourceFile.close();

    // Open input file
    inputFile.open(inFileName, fstream::in);
    string fileNameWithoutExt = getFileNameWithoutExt(inFileName);

    int warningCount = 0;
    map<string, SymbolTable *> symbolTableMap;
    location loc;
    TokenNode *programNode = new TokenNode(loc);

    scanner = new FlexScanner(&inputFile, &cout, showToken, showLine);
    parser = new BisonParser(*scanner, symbolTableMap, showParsing, &warningCount, programNode);

    // perform parsing
    if (parser->parse() == 1)
    {
        cerr << "Parsing error !" << endl;
        return -1;
    }
    cout << endl;
    cout << "Total warning: " << warningCount << endl;
    cout << endl;
    inputFile.close();

    if (warningCount > 0 || !doCodeGeneration)
    {
        // Skip code generation
        return 0;
    }

    // Code generation
    ofstream outputFile;

    string outFileName = fileNameWithoutExt + ".jasm";
    string className = programNode->symbolTableEntry->name;

    outputFile.open(outFileName);
    cout << "Generating java bytecode " << outFileName << endl;
    CodeGenerator *codeGenerator = new CodeGenerator(&outputFile, symbolTableMap, sourceLines, outputComment, outputOperatorType);
    codeGenerator->GenerateJasm(programNode);
    outputFile.close();
    cout << outFileName << " generated." << endl;

    // Check javaa
    ifstream javaaFile("./javaa");
    if (!javaaFile.good())
    {
        cerr << "Can not find javaa, exiting..." << endl;
        return -2;
    }
    javaaFile.close();

    // Remove old class file
    string classFileName = className + ".class";
    remove(classFileName.c_str());
    // Assemable
    cout << "Assemabling using javaa.exe" << endl;
    string command = "./javaa " + outFileName;
    system(command.c_str());

    // Check class output
    ifstream javaClassFile("./" + classFileName);
    if (!javaClassFile.good())
    {
        cerr << "Assemabling fail." << endl;
        return -3;
    }
    javaClassFile.close();
    cout << "Assemabling successed." << endl
         << endl;

    // Execute java code
    if (runCode)
    {
        system("reset");
        cout << "Executing java class " << classFileName << endl;
        cout << "---------------------------" << endl;
        command = "java " + className;
        system(command.c_str());
    }

    return 0;
}
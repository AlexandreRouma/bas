#pragma once
#include <vector>
#include <string>
#include <memory>

namespace lexer {
    enum TokenType {
        INVALID = -1,
        SYMBOL,
        WORD,
        STRING
    };

    struct TokenPosition {
        int line;
        int column;
    };

    class TokenClass {
    public:
        std::string dumpPos() {
            char buf[4096];
            sprintf(buf, "%s (line %d, column %d)", file.c_str(), pos.line + 1, pos.column + 1);
            return std::string(buf);
        }

        TokenType type;
        
        // Location in code
        std::string file;
        TokenPosition pos;
    
        // Arguments
        std::string str;
        char sym;
    };

    typedef std::shared_ptr<TokenClass> Token;

    int lex(std::string file, std::string code, std::vector<Token>& tks);
    void dump(const std::vector<Token>& tks);
}
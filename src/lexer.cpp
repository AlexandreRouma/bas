#include "lexer.h"
#include "buffer.h"
#include <stdio.h>
#include <stdexcept>

#define INCREMENT_FILE_CURSOR   [&](int i, char c){ if (c == '\n') { pos.line++; pos.column = 0; } else if (std::isprint(c)) { pos.column++; } ; return true; }

namespace lexer {
    Token newToken(TokenType type, std::string file, TokenPosition pos) {
        Token tk(new TokenClass);
        tk->type = type;
        tk->file = file;
        tk->pos = pos;
        return tk;
    }

    Token newSymbol(char sym, std::string file, TokenPosition pos) {
        Token tk = newToken(TokenType::SYMBOL, file, pos);
        tk->sym = sym;
        return tk;
    }

    Token newWord(std::string str, std::string file, TokenPosition pos) {
        Token tk = newToken(TokenType::WORD, file, pos);
        tk->str = str;
        return tk;
    }

    Token newString(std::string str, std::string file, TokenPosition pos) {
        Token tk = newToken(TokenType::STRING, file, pos);
        tk->str = str;
        return tk;
    }

    int lex(std::string file, std::string code, std::vector<Token>& tks) {
        buffer<std::string> str(code);
        TokenPosition pos;
        pos.line = 0;
        pos.column = 0;
        int peeked = 0;

        while (str.available()) {
            // Skip spaces
            if (peeked = str.peek(-1, [=](int i, char c){ 
                return c == ' ' || c == '\t' || c == '\r' || c == '\n' || ! std::isprint(c);
            })) {
                str.consume(peeked, INCREMENT_FILE_CURSOR);
                continue;
            }

            // Skip semicolumn comments
            peeked = str.peek(-1, [=](int i, char c){ 
                if ((i == 0) && c != ';') { return false; }
                else if (c == '\n') { return false; }
                return true;
            });
            if (peeked >= 1) {
                str.consume(peeked, INCREMENT_FILE_CURSOR);
                continue;
            }

            // Skip line comments
            peeked = str.peek(-1, [=](int i, char c){ 
                if ((i == 0 || i == 1) && c != '/') { return false; }
                else if (c == '\n') { return false; }
                return true;
            });
            if (peeked >= 2) {
                str.consume(peeked, INCREMENT_FILE_CURSOR);
                continue;
            }

            // Skip block comments
            bool blockCommentValid = false;
            char lastChar = 0;
            peeked = str.peek(-1, [&](int i, char c){ 
                if (i == 0 && c != '/') { return false; }
                else if (i == 1 && c != '*') { return false; }
                else if (c == '/' && lastChar == '*') {
                    blockCommentValid = true;
                    return false;
                }
                lastChar = c;
                return true;
            });
            if (blockCommentValid) {
                str.consume(peeked + 1, INCREMENT_FILE_CURSOR);
                continue;
            }
            else if (peeked >= 2) {
                return -1;
            }

            // Lex string
            // TODO:  Pretty sure "\\" would break it
            bool stringValid = false;
            std::string lexedString = "";
            lastChar = 0;
            peeked = str.peek(-1, [&](int i, char c){ 
                if (i == 0 && c != '"') { return false; }
                else if (c == '"' && lastChar && lastChar != '\\') {
                    stringValid = true;
                    return false;
                }
                if (!i) { return true; }
                lexedString += c;
                lastChar = c;
                return true;
            });
            if (stringValid) {
                tks.push_back(newString(lexedString, file, pos));
                str.consume(peeked + 1, INCREMENT_FILE_CURSOR);
                continue;
            }
            else if (peeked >= 1) {
                return -1;
            }

            // Lex words
            std::string wordStr = "";
            if (peeked = str.peek(-1, [&](int i, char c){
                if (!std::isalnum(c) && c != '_') { return false; }
                wordStr += c;
                return true;
            })) {
                tks.push_back(newWord(wordStr, file, pos));
                str.consume(peeked, INCREMENT_FILE_CURSOR);
                continue;
            }

            // Otherwise, it must be a symbol
            str.peek(1, [&](int i, char c){
                tks.push_back(newSymbol(c, file, pos));
                return false;
            });
            str.consume(1, INCREMENT_FILE_CURSOR);
        }

        return 0;
    }


    // Just for debug
    void dump(const std::vector<Token>& tks) {
        for (const auto& tk : tks) {
            switch (tk->type) {
                case TokenType::SYMBOL:
                    printf("[SYMBOL '%c', %s:(line %d, column %d)]\n", tk->sym, tk->file.c_str(), tk->pos.line + 1, tk->pos.column + 1);
                    break;
                case TokenType::WORD:
                    printf("[WORD '%s', %s:(line %d, column %d)]\n", tk->str.c_str(), tk->file.c_str(), tk->pos.line + 1, tk->pos.column + 1);
                    break;
                case TokenType::STRING:
                    printf("[STRING '%s', %s:(line %d, column %d)]\n", tk->str.c_str(), tk->file.c_str(), tk->pos.line + 1, tk->pos.column + 1);
                    break;
                default:
                    printf("[INVALID, %s:(line %d, column %d)]\n", tk->file.c_str(), tk->pos.line + 1, tk->pos.column + 1);
                    break;
            }
        }
    }
}
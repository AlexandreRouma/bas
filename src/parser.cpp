#include "parser.h"
#include <stdarg.h>
#include <fstream>
#include <filesystem>

namespace parser {
    template<typename... Args>
    void throwForm(const char* fmt, Args... args) {
        char err[4096];
        sprintf(err, fmt, args...);
        throw std::runtime_error(err);
    }

    bool expectSymbol(buffer<std::vector<lexer::Token>>& tks, char sym) {
        if (!tks.available()) { return false; }
        return tks[0]->type == lexer::TokenType::SYMBOL && (!sym || tks[0]->sym == sym);
    }

    bool expectWord(buffer<std::vector<lexer::Token>>& tks, std::string word) {
        if (!tks.available()) { return false; }
        return tks[0]->type == lexer::TokenType::WORD && (word.empty() || tks[0]->str == word);
    }

    bool expectString(buffer<std::vector<lexer::Token>>& tks, std::string str) {
        if (!tks.available()) { return false; }
        return tks[0]->type == lexer::TokenType::STRING && (str.empty() || tks[0]->str == str);
    }

    int parse(std::vector<lexer::Token>& tokens, BinaryBuilder<uint16_t>& bb) {
        buffer<std::vector<lexer::Token>> tks(tokens);
        std::map<std::string, uint16_t> labels;
        std::vector<Insertion> insertions;

        while (tks.available()) {
            if (parseStatement(tks, bb, labels, insertions)) { continue; }

            std::string lblName;
            lexer::Token ft = tks.first();
            if (parseLabel(tks, lblName)) {
                if (labels.find(lblName) != labels.end()) {
                    throwForm("Label '%s' already exists: %s", lblName.c_str(), ft->dumpPos().c_str());
                }
                labels[lblName] = bb.tell();
                continue;
            }

            if (parseInstruction(tks, bb, insertions)) { continue; }

            throwForm("Unknown instruction at %s: %s", tks.first()->dumpPos().c_str(), tks.first()->str.c_str());
        }

        // Link
        for (auto const& ins : insertions) {
            if (labels.find(ins.label) == labels.end()) {
                throwForm("Label '%s' doesn't exists: %s", ins.label.c_str(), ins.tok->dumpPos().c_str());
            }
            bb.putAt(labels[ins.label], ins.addr);
        }

        return 0;
    }

    // Generic parsers
    bool parseChar(buffer<std::vector<lexer::Token>>& tks, uint8_t& val) {
        if (!expectSymbol(tks, '\'')) { return false; }
        int check = tks.tell();
        tks.consume(1);

        if (!expectString(tks) || tks.first()->str.size() != 1) {
            tks.seek(check);
            return false;
        }
        val = tks.first()->str[0];
        tks.consume(1);

        if (!expectSymbol(tks, '\'')) {
            tks.seek(check);
            return false;
        }
        tks.consume(1);

        return true;
    }

    bool parseNum(buffer<std::vector<lexer::Token>>& tks, uint16_t& val) {
        if (!expectWord(tks)) { return false; }
        std::string numStr = tks.first()->str;

        // If just a normal number
        bool norm = true;
        for (const char& c : numStr) {
            if (!std::isdigit(c)) {
                norm = false;
                break;
            }
        }
        if (norm) {
            val = std::stoi(numStr);
            tks.consume(1);
            return true;
        }

        // If number is hex
        if (numStr.rfind("0x", 0) == 0) {
            numStr = numStr.substr(2);
            bool hex = true;
            for (const char& c : numStr) {
                if (!std::isxdigit(c)) {
                    hex = false;
                    break;
                }
            }
            if (hex) {
                val = std::stoi(numStr, nullptr, 16);
                tks.consume(1);
                return true;
            }
        }

        return false;
    }

    // Argument parsers
    bool parseCond(buffer<std::vector<lexer::Token>>& tks, uint8_t& condId) {
        if (!expectSymbol(tks, '@')) { return false; }
        int check = tks.tell();
        tks.consume(1);

        for (auto const& [cond, id] : CONDS) {
            if (expectWord(tks, cond)) {
                condId = id;
                tks.consume(1);
                return true;
            }
        }

        tks.seek(check);
        return false;
    }

    bool parseReg(buffer<std::vector<lexer::Token>>& tks, uint8_t& regId) {
        for (auto const& [reg, id] : REGS) {
            if (expectWord(tks, reg)) {
                regId = id;
                tks.consume(1);
                return true;
            }
        }
        return false;
    }

    bool parseMemReg(buffer<std::vector<lexer::Token>>& tks, uint8_t& regId) {
        if (!expectSymbol(tks, '[')) { return false; }
        int check = tks.tell();
        tks.consume(1);

        if (!parseReg(tks, regId)) {
            tks.seek(check);
            return false;
        }

        if (!expectSymbol(tks, ']')) {
            tks.seek(check);
            return false;
        }
        tks.consume(1);

        return true;
    }

    bool parseImm(buffer<std::vector<lexer::Token>>& tks, uint16_t& val, std::string& label) {
        // Try parsing a number
        if (parseNum(tks, val)) { return true; }

        // Try parsing a char
        uint8_t ch;
        if (parseChar(tks, ch)) {
            val = ch;
            return true;
        }

        // Try parsing a label
        if (expectWord(tks)) {
            label = tks.first()->str;
            tks.consume(1);
            return true;
        }

        return false;
    }

    bool parseMemImm(buffer<std::vector<lexer::Token>>& tks, uint16_t& addr, std::string& label) {
        if (!expectSymbol(tks, '[')) { return false; }
        int check = tks.tell();
        tks.consume(1);

        if (!parseImm(tks, addr, label)) {
            tks.seek(check);
            return false;
        }

        if (!expectSymbol(tks, ']')) {
            tks.seek(check);
            return false;
        }
        tks.consume(1);

        return true;
    }

    // Language parsers
    bool parseStatement(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        if (!expectSymbol(tks, '.')) { return false; }
        int check = tks.tell();
        tks.consume(1);

        if (!expectWord(tks)) {
            tks.seek(check);
            return false;
        }
        lexer::Token st = tks.first();
        std::string statementName = tks.first()->str;
        tks.consume(1);

        if (STATEMENTS.find(statementName) == STATEMENTS.end()) {
            throwForm("Unknown assembler statement '%s': %s", statementName.c_str(), st->dumpPos().c_str());
        }

        STATEMENTS[statementName].handler(tks, bb, labels, insertions);

        return true;
    }

    bool parseLabel(buffer<std::vector<lexer::Token>>& tks, std::string& name) {
        if (!expectWord(tks)) { return false; }
        name = tks.first()->str;
        int check = tks.tell();
        tks.consume(1);

        if (!expectSymbol(tks, ':')) {
            tks.seek(check);
            return false;
        }
        tks.consume(1);

        return true;
    }

    bool parseInstruction(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::vector<Insertion>& insertions) {
        if (!expectWord(tks)) { return false; }
        lexer::Token ft = tks.first();
        std::string mnem = ft->str;
        int check = tks.tell();
        tks.consume(1);
        int argCheck = tks.tell();

        // First a matching instruction
        for (auto const& ins : INSTRS) {
            uint8_t srcCond = 0;
            uint8_t dstCond = 0;
            uint8_t srcId = 0;
            uint8_t dstId = 0;
            uint16_t srcImm = 0;
            uint16_t dstImm = 0;
            std::string srcImmLabel = "";
            std::string dstImmLabel = "";

            if (ins.mnemonic != mnem) { continue; }
            tks.seek(argCheck);

            // If the instruction is conditional, grab condition
            if (ins.srcType == ArgType::COND) {
                parseCond(tks, srcId);
            }
            else if (ins.dstType == ArgType::COND) {
                parseCond(tks, dstId);
            }

            // Work around for the dumb structor of the jump opcode
            if ((mnem == "jmp" || mnem == "call") && ins.dstType == ArgType::IMM) {
                srcId |= 0b10000;
            }

            // Parse dst argument
            if (ins.dstType == ArgType::IMM) { if (!parseImm(tks, dstImm, dstImmLabel)) { continue; } }
            else if (ins.dstType == ArgType::MEM_IMM) { if (!parseMemImm(tks, dstImm, dstImmLabel)) { continue; } }
            else if (ins.dstType == ArgType::REG) { if (!parseReg(tks, dstId)) { continue; } }
            else if (ins.dstType == ArgType::MEM_REG) { if (!parseMemReg(tks, dstId)) { continue; } }
            else if (ins.dstType == ArgType::ID_IMM) {
                uint16_t immId;
                std::string dummyLabel = "";
                if (!parseImm(tks, immId, dummyLabel)) { continue; }
                if (!dummyLabel.empty()) { continue; }
                dstId = immId;
            }

            // Check for a comma if needed
            if (ins.argCount == 2) {
                if (!expectSymbol(tks, ',')) { break; }
                tks.consume(1);
            }

            // Parse src argument
            if (ins.srcType == ArgType::IMM) { if (!parseImm(tks, srcImm, srcImmLabel)) { continue; } }
            else if (ins.srcType == ArgType::MEM_IMM) { if (!parseMemImm(tks, srcImm, srcImmLabel)) { continue; } }
            else if (ins.srcType == ArgType::REG) { if (!parseReg(tks, srcId)) { continue; } }
            else if (ins.srcType == ArgType::MEM_REG) { if (!parseMemReg(tks, srcId)) { continue; } }
            else if (ins.srcType == ArgType::ID_IMM) {
                uint16_t immId;
                std::string dummyLabel = "";
                if (!parseImm(tks, immId, dummyLabel)) { continue; }
                if (!dummyLabel.empty()) { continue; }
                srcId = immId;
            }

            // Write opcode
            bb.put(buildInstruction(ins.opcode, dstId, srcId));

            // Write imm if needed
            uint16_t immAddr = bb.tell();
            if (ins.srcType == ArgType::IMM || ins.srcType == ArgType::MEM_IMM) {
                bb.put(srcImmLabel.empty() ? srcImm : 0);
                if (!srcImmLabel.empty()) { insertions.push_back(Insertion{ ft, srcImmLabel, immAddr }); }
            }
            if (ins.dstType == ArgType::IMM || ins.dstType == ArgType::MEM_IMM) {
                bb.put(dstImmLabel.empty() ? dstImm : 0);
                if (!dstImmLabel.empty()) { insertions.push_back(Insertion{ ft, dstImmLabel, immAddr }); }
            }

            return true;
        }
        
        tks.seek(check);
        return false;
    }

    uint16_t buildInstruction(uint8_t opcode, uint8_t dst, uint8_t src) {
        return opcode | (dst << 6) | (src << 11);
    }
}

// Statements
namespace parser::statements {
    void org(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        uint16_t num;
        if (!parseNum(tks, num)) {
            throwForm("Expected number at %s", tks.first()->dumpPos().c_str());
        }

        bb.seek(num);
    }

    void incbin(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        if (!expectString(tks)) {
            throwForm("Expected file path at %s", tks.first()->dumpPos().c_str());
        }
        lexer::Token tk = tks.first();
        std::string str = tk->str;
        tks.consume(1);

        // Open file
        std::string basePath = std::filesystem::path(tk->file).parent_path().string();
        std::ifstream file(basePath + "/" + str, std::ios::in | std::ios::binary | std::ios::ate);
        if (!file.is_open()) {
            throwForm("Could not open file %s", (basePath + "/" + str).c_str());
        }

        // Get length
        int len = file.tellg();
        int wc = len / 2;
        file.seekg(0);

        // Allocater and read into buffer
        uint16_t* words = new uint16_t[wc];
        file.read((char*)words, len);
        file.close();

        // Write to binary
        bb.write(words, wc);

        delete[] words;
    }

    void str(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        if (!expectString(tks)) {
            throwForm("Expected string at %s", tks.first()->dumpPos().c_str());
        }
        std::string str = tks.first()->str;
        tks.consume(1);

        for (char c : str) {
            bb.put(c);
        }
        bb.put(0);
    }

    void skip(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        uint16_t num;
        if (!parseNum(tks, num)) {
            throwForm("Expected number at %s", tks.first()->dumpPos().c_str());
        }

        for (int i = 0; i < num; i++) {
            bb.put(0);
        }
    }

    void align(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        uint16_t num;
        if (!parseNum(tks, num)) {
            throwForm("Expected number at %s", tks.first()->dumpPos().c_str());
        }

        while (bb.tell() % num) {
            bb.put(0);
        }
    }

    void word(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        uint16_t num;
        if (!parseNum(tks, num)) {
            throwForm("Expected number at %s", tks.first()->dumpPos().c_str());
        }
        bb.put(num);
    }

    void define(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions) {
        if (!expectWord(tks)) {
            throwForm("Expected word at %s", tks.first()->dumpPos().c_str());
        }
        std::string labelName = tks.first()->str;
        tks.consume(1);
        
        uint16_t num;
        if (!parseNum(tks, num)) {
            throwForm("Expected number at %s", tks.first()->dumpPos().c_str());
        }
        
        if (labels.find(labelName) != labels.end()) {
            throwForm("Label called '%s' already exists: %s", labelName.c_str(), tks.first()->dumpPos().c_str());
        }

        labels[labelName] = num;
    }
}
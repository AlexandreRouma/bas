#pragma once
#include "lexer.h"
#include "buffer.h"
#include <map>
#include <stdexcept>
#include "binary_builder.h"

#define INDENT_PRINT(n) for (int i = 0; i < n; i++) { printf("    "); };

namespace parser {
    const std::map<std::string, uint8_t> REGS = {
        // Mnem  Id
        { "r0",  0 },
        { "r1",  1 },
        { "r2",  2 },
        { "r3",  3 },
        { "r4",  4 },
        { "r5",  5 },
        { "r6",  6 },
        { "rsp", 7 },
    };

    enum ArgType {
        NONE,
        IMM,
        MEM_IMM,
        REG,
        MEM_REG,
        ID_IMM,
        COND
    };

    struct InstDesc {
        std::string mnemonic;
        uint8_t opcode;
        int argCount;
        ArgType dstType;
        ArgType srcType;
    };

    const std::vector<InstDesc> INSTRS = {
        // Mnemo    Op      N   Dst       Src
        { "ldi",    0x00,   2,  REG     , IMM       },
        { "mov",    0x01,   2,  REG     , REG       },
        { "xch",    0x02,   2,  REG     , REG       },
        { "ld",     0x03,   2,  REG     , MEM_REG   },
        { "ld",     0x17,   2,  REG     , MEM_IMM   },
        { "st",     0x05,   2,  MEM_REG , REG       },
        { "st",     0x04,   2,  MEM_IMM , REG       },
        { "add",    0x06,   2,  REG     , REG       },
        { "sub",    0x07,   2,  REG     , REG       },
        { "cmp",    0x08,   2,  REG     , REG       },
        { "mul",    0x09,   2,  REG     , REG       },
        { "inc",    0x0A,   1,  REG     , NONE      },
        { "dec",    0x0B,   1,  REG     , NONE      },
        { "xor",    0x0C,   2,  REG     , REG       },
        { "and",    0x0D,   2,  REG     , REG       },
        { "or",     0x0E,   2,  REG     , REG       },
        { "shl",    0x0F,   2,  REG     , ID_IMM    },
        { "shr",    0x10,   2,  REG     , ID_IMM    },
        { "jmp",    0x11,   1,  REG     , COND      },
        { "jmp",    0x11,   1,  IMM     , COND      },
        { "push",   0x13,   1,  REG     , NONE      },
        { "push",   0x12,   1,  IMM     , NONE      },
        { "pop",    0x14,   1,  REG     , NONE      },
        { "hlt",    0x15,   1,  NONE    , NONE      },
        { "ret",    0x16,   1,  NONE    , NONE      },
        { "call",   0x18,   1,  REG     , NONE      },
        { "call",   0x18,   1,  IMM     , NONE      },
    };

    const std::map<std::string, uint8_t> CONDS = {
        // Mnem  Id
        { "nc",  0b0000 },
        { "eq",  0b1110 },
        { "ne",  0b1111 },
        { "gr",  0b1000 },
        { "ge",  0b1001 },
        { "lo",  0b0100 },
        { "le",  0b0101 },
        { "cf",  0b0001 }
    };

    struct Insertion {
        lexer::Token tok;
        std::string label;
        uint16_t addr;
    };

    struct Statement {
        void (*handler)(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
    };

    // Statements
    namespace statements {
        void org(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void incbin(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void str(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void skip(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void align(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void word(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void call(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
        void define(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
    }

    inline std::map<std::string, Statement> STATEMENTS = {
        // Mnem       Handler
        { "org",    { statements::org } },
        { "incbin", { statements::incbin } },
        { "str",    { statements::str } },
        { "skip",   { statements::skip } },
        { "align",  { statements::align } },
        { "word",   { statements::word } },
        { "call",   { statements::call } },
        { "define", { statements::define } },
    };

    bool expectSymbol(buffer<std::vector<lexer::Token>>& tks, char sym = 0);
    bool expectWord(buffer<std::vector<lexer::Token>>& tks, std::string word = "");
    bool expectString(buffer<std::vector<lexer::Token>>& tks, std::string str = "");

    int parse(std::vector<lexer::Token>& tokens, BinaryBuilder<uint16_t>& bb);

    // Generic parsers
    bool parseChar(buffer<std::vector<lexer::Token>>& tks, uint8_t& val);
    bool parseNum(buffer<std::vector<lexer::Token>>& tks, uint16_t& val);

    // Argument parsers
    bool parseCond(buffer<std::vector<lexer::Token>>& tks, uint8_t& condId);
    bool parseReg(buffer<std::vector<lexer::Token>>& tks, uint8_t& regId);
    bool parseMemReg(buffer<std::vector<lexer::Token>>& tks, uint8_t& regId);
    bool parseImm(buffer<std::vector<lexer::Token>>& tks, uint16_t& val, std::string& label);
    bool parseMemImm(buffer<std::vector<lexer::Token>>& tks, uint16_t& addr, std::string& label);

    // Language parsers
    bool parseStatement(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::map<std::string, uint16_t>& labels, std::vector<Insertion>& insertions);
    bool parseLabel(buffer<std::vector<lexer::Token>>& tks, std::string& name);
    bool parseInstruction(buffer<std::vector<lexer::Token>>& tks, BinaryBuilder<uint16_t>& bb, std::vector<Insertion>& insertions);

    uint16_t buildInstruction(uint8_t opcode, uint8_t dst, uint8_t src);

    
}
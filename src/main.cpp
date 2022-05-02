#include <stdio.h>
#include <fstream>
#include <sstream>
#include "lexer.h"
#include "parser.h"
#include "command_args.h"
#include <filesystem>

enum OutFormat {
    BIN,
    POKE,
    HEADER
};

int main(int argc, char* argv[]) {
    CommandArgsParser cargs;
    cargs.define('h', "help", "Show help");
    cargs.define<std::string>('f', "format", "Output format ('bin', 'poke' or 'header')", "bin");
    cargs.define<std::string>('o', "output", "Output file", "a.out");
    cargs.parse(argc, argv);

    if (cargs["help"].b()) {
        cargs.showHelp();
        return 0;
    }

    // Check if an input was given
    if (cargs.loneArgs.empty()) {
        cargs.showHelp();
        fprintf(stderr, "No input file given...\n");
        return -1;
    }

    // Check output format
    std::string fstr = cargs["format"];
    OutFormat format;
    if (fstr == "bin") {
        format = OutFormat::BIN;
    }
    else if (fstr == "poke") {
        format = OutFormat::POKE;
    }
    else if (fstr == "header") {
        format = OutFormat::HEADER;
    }
    else {
        cargs.showHelp();
        fprintf(stderr, "Invalid output format: %s\n", fstr.c_str());
        return -1;
    }

    // Lex source files
    std::vector<lexer::Token> tks;
    for (auto const& path : cargs.loneArgs) {
        // Load file
        std::string code = "";
        std::stringstream buffer;
        std::ifstream file(path, std::ios::in);
        buffer << file.rdbuf();
        code = buffer.str();

        // Lex content
        int ret = lexer::lex(path, code, tks);
        if (ret) {
            fprintf(stderr, "Lexing failed\n");
            return -1;
        }
    }

    // Parse and build binary image
    BinaryBuilder<uint16_t> bb;
    try {
        parser::parse(tks, bb);
    }
    catch (std::runtime_error e) {
        fprintf(stderr, "ERROR: %s\n", e.what());
        return -1;
    }

    // Output in chosen format
    std::ofstream outfile(cargs["output"].s(), std::ios::out | std::ios::binary);
    if (format == OutFormat::BIN) {
        outfile.write((char*)bb.getData(), bb.getSize() * sizeof(uint16_t));
    }
    else if (format == OutFormat::POKE) {
        const uint16_t* data = bb.getData();
        char buf[1024];
        for (int i = 0; i < bb.getSize(); i++) {
            sprintf(buf, "debug::poke(0x%04X, 0x%04X);\n", i, data[i]);
            outfile.write(buf, strlen(buf));
        }
    }
    else if (format == OutFormat::HEADER) {
        const uint16_t* data = bb.getData();
        char buf[1024];
        std::string begin = "#pragma once\n#include <stdint.h>\n\nconst uint16_t rom_bin[] = {\n";
        std::string end = "};\n";
        outfile.write(begin.c_str(), begin.length());
        for (int i = 0; i < bb.getSize(); i++) {
            sprintf(buf, "    0x%04X,\n", data[i]);
            outfile.write(buf, strlen(buf));
        }
        outfile.write(end.c_str(), end.length());
        sprintf(buf, "const int rom_bin_len = %d;\n", bb.getSize());
            outfile.write(buf, strlen(buf));
    }
    outfile.close();

    return 0;
}
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <unordered_map>
#include <iomanip>
#include <algorithm>
#include <cstdint>

enum class Section { NONE, DATA, TEXT, CONST };

const std::unordered_map<std::string, uint8_t> OPCODES = {
    {"NOP",0x00},

    {"LW",0x01},{"SW",0x02},

    {"ADD",0x03},{"ADDI",0x04},
    {"ADDU",0x05},{"ADDUI",0x06},

    {"SUB",0x07},{"SUBI",0x08},
    {"SUBU",0x09},{"SUBUI",0x0A},

    {"AND",0x0B},{"ANDI",0x0C},
    {"OR",0x0D},{"ORI",0x0E},
    {"XOR",0x0F},{"XORI",0x10},

    {"SLL",0x11},{"SLLI",0x12},
    {"SRL",0x13},{"SRLI",0x14},
    {"SRA",0x15},{"SRAI",0x16},

    {"SLT",0x17},{"SLTI",0x18},
    {"SLTU",0x19},{"SLTUI",0x1A},

    {"SGT",0x1B},{"SGTI",0x1C},
    {"SGTU",0x1D},{"SGTUI",0x1E},

    {"SLE",0x1F},{"SLEI",0x20},
    {"SLEU",0x21},{"SLEUI",0x22},

    {"SGE",0x23},{"SGEI",0x24},
    {"SGEU",0x25},{"SGEUI",0x26},

    {"SEQ",0x27},{"SEQI",0x28},
    {"SNE",0x29},{"SNEI",0x2A},

    {"BEQZ",0x2B},{"BNEZ",0x2C},
    {"J",0x2D},{"JR",0x2E},
    {"JAL",0x2F},{"JALR",0x30},
    {"PCH",0x31},
    {"PD",0x32},
    {"PDU",0x33},
    {"GD",0x34},
    {"GDU",0x35}
};


[[noreturn]] void asmError(const std::string& msg) {
    std::cerr << "Assembler error: " << msg << std::endl;
    exit(1);
}

int regNum(const std::string& r) {
    if (r.empty() || r[0] != 'R') {
        std::cerr << "Invalid register token: [" << r << "]\n";
        exit(1);
    }
    return std::stoi(r.substr(1));
}

uint32_t encodeR(uint8_t op, int rd, int rs1, int rs2) {
    return (op << 26) | (rd << 21) | (rs1 << 16) | (rs2 << 11);
}

uint32_t encodeI(uint8_t op, int rd, int rs1, int imm) {
    return (op << 26) | (rd << 21) | (rs1 << 16) | (imm & 0xFFFF);
}

uint32_t encodeJ(uint8_t op, uint32_t addr) {
    return (op << 26) | (addr & 0x03FFFFFF);
}

int main(int argc, char* argv[]) {
    if (argc != 4) {
        std::cerr << "Usage: ./dlx_asm <input>.dlx <data>.mif <code>.mif\n";
        return 1;
    }

    std::ifstream in(argv[1]);
    if (!in) {
        std::cerr << "Cannot open input file\n";
        return 1;
    }

    std::vector<std::string> dataLines, textLines, constLines;
    Section section = Section::NONE;
    std::string line;

    /* ---------- PASS 1: PARSE ---------- */
    while (std::getline(in, line)) {
        auto c = line.find(';');
        if (c != std::string::npos) line = line.substr(0, c);

        if (line.find(".data")  != std::string::npos) { section = Section::DATA; continue; }
        if (line.find(".text")  != std::string::npos) { section = Section::TEXT; continue; }
        if (line.find(".const") != std::string::npos) { section = Section::CONST; continue; }

        if (line.find_first_not_of(" \t\r\n") == std::string::npos)
            continue;

        if (section == Section::DATA) dataLines.push_back(line);
        if (section == Section::TEXT) textLines.push_back(line);
        if (section == Section::CONST) constLines.push_back(line);
    }

    /* ---------- DATA SYMBOLS ---------- */
    std::unordered_map<std::string, uint32_t> dataSymbols;
    std::vector<uint32_t> dataMem;
    uint32_t dataAddr = 0;

    for (auto& l : dataLines) {
        std::stringstream ss(l);
        std::string name;
        int count;
        ss >> name >> count;
        dataSymbols[name] = dataAddr;

        for (int i = 0; i < count; i++) {
            int v;
            ss >> v;
            dataMem.push_back(v);
            dataAddr++;
        }
    }
    
    /* ---------- CONST SYMBOLS ---------- */
    std::unordered_map<std::string, uint32_t> constSymbols;
    std::vector<uint32_t> constMem;
    uint32_t constAddr = 0;

    for (auto& l : constLines) {
        std::stringstream ss(l);

        std::string name;
        int length;

        ss >> name >> length;

        // IMPORTANT: offset AFTER data
        constSymbols[name] = dataMem.size() + constAddr;

        std::string rest;
        std::getline(ss, rest);

        // extract string between quotes
        auto first = rest.find('"');
        auto last = rest.rfind('"');

        if (first == std::string::npos || last == std::string::npos || last <= first)
            asmError("Invalid string in .const");

        std::string str = rest.substr(first + 1, last - first - 1);

        // store length first
        constMem.push_back(str.size());
        constAddr++;

        // store characters
        for (size_t i = 0; i < str.size(); i++) {
            if (str[i] == '\\' && i + 1 < str.size()) {
                if (str[i + 1] == 'n') {
                    constMem.push_back(10); // newline
                    i++;
                } else {
                    constMem.push_back((uint32_t)str[i + 1]);
                    i++;
                }
            } else {
                constMem.push_back((uint32_t)str[i]);
            }
            constAddr++;
        }
    }

    /* ---------- CODE LABELS ---------- */
    std::unordered_map<std::string, uint32_t> labels;
    uint32_t pc = 0;

    for (auto& l : textLines) {
        std::stringstream ss(l);
        std::string tok;
        ss >> tok;

        if (OPCODES.find(tok) == OPCODES.end()){
            if (labels.count(tok))
                asmError("Duplicate label: " + tok);
            // labels[tok] = pc;
            labels[tok] = pc;
        }
        else {
            pc++;
        }
    }

    /* ---------- PASS 2: ENCODE ---------- */
    std::vector<uint32_t> codeMem;
    std::vector<std::string> codeText;

    for (auto l : textLines) {
        std::string originalLine = l;

        // remove leading spaces
        originalLine.erase(0, originalLine.find_first_not_of(" \t"));

        // remove inline comments (anything after ;)
        auto commentPos = originalLine.find(';');
        if (commentPos != std::string::npos)
            originalLine = originalLine.substr(0, commentPos);

        // trim again
        originalLine.erase(originalLine.find_last_not_of(" \t") + 1);

        std::string annotatedLine = originalLine;
        std::replace(l.begin(), l.end(), ',', ' ');
        std::replace(l.begin(), l.end(), '(', ' ');
        std::replace(l.begin(), l.end(), ')', ' ');

        std::stringstream ss(l);
        std::string op;
        ss >> op;

        if (OPCODES.find(op) == OPCODES.end())
            continue;

        uint8_t opcode = OPCODES.at(op);
        uint32_t inst = 0;

        if (op == "ADD") {
            std::string rd, rs1, rs2;
            ss >> rd >> rs1 >> rs2;
            inst = encodeR(opcode, regNum(rd), regNum(rs1), regNum(rs2));
        }
        else if (op == "ADDU" || op == "SUB" || op == "SUBU" ||
                op == "AND"  || op == "OR"  || op == "XOR"  ||
                op == "SLL"  || op == "SRL" || op == "SRA"  ||
                op == "SLT"  || op == "SLTU"||
                op == "SGT"  || op == "SGTU"||
                op == "SLE"  || op == "SLEU"||
                op == "SGE"  || op == "SGEU"||
                op == "SEQ"  || op == "SNE") {
            std::string rd, rs1, rs2;
            ss >> rd >> rs1 >> rs2;
            inst = encodeR(opcode, regNum(rd), regNum(rs1), regNum(rs2));
        }
        else if (op == "ADDI" || op == "ADDUI" ||
                op == "SUBI" || op == "SUBUI" ||
                op == "ANDI" || op == "ORI"   || op == "XORI" ||
                op == "SLLI" || op == "SRLI"  || op == "SRAI" ||
                op == "SLTI" || op == "SLTUI" ||
                op == "SGTI" || op == "SGTUI" ||
                op == "SLEI" || op == "SLEUI" ||
                op == "SGEI" || op == "SGEUI" ||
                op == "SEQI" || op == "SNEI") {
            std::string rd, rs1;
            std::string immStr;
            ss >> rd >> rs1 >> immStr;
            int imm;
            if (dataSymbols.count(immStr)) imm = dataSymbols.at(immStr);
            else if (constSymbols.count(immStr)) imm = constSymbols.at(immStr);
            else if (labels.count(immStr)) imm = labels.at(immStr);
            else imm = std::stoi(immStr);
            inst = encodeI(opcode, regNum(rd), regNum(rs1), imm);
        }
        else if (op == "LW") {
            std::string rd, offsetStr, base;
            ss >> rd >> offsetStr >> base;

            int offset;

            // check if number
            if (isdigit(offsetStr[0]) || (offsetStr[0] == '-' && isdigit(offsetStr[1]))) {
                offset = std::stoi(offsetStr);
            }
            else if (dataSymbols.count(offsetStr)) {
                offset = dataSymbols.at(offsetStr);
            }
            else if (constSymbols.count(offsetStr)) {
                offset = constSymbols.at(offsetStr);
            }
            else {
                asmError("Undefined symbol: " + offsetStr);
            }

            inst = encodeI(opcode, regNum(rd), regNum(base), offset);
        }
        else if (op == "SW") {
            std::string offsetStr, base, rs;
            ss >> offsetStr >> base >> rs;

            int offset;

            if (isdigit(offsetStr[0]) || (offsetStr[0] == '-' && isdigit(offsetStr[1]))) {
                offset = std::stoi(offsetStr);
            }
            else if (dataSymbols.count(offsetStr)) {
                offset = dataSymbols.at(offsetStr);
            }
            else if (constSymbols.count(offsetStr)) {
                offset = constSymbols.at(offsetStr);
            }
            else {
                asmError("Undefined symbol: " + offsetStr);
            }

            inst = encodeI(opcode, regNum(rs), regNum(base), offset);
        }
        else if (op == "BEQZ" || op == "BNEZ") {
            std::string rs, lbl;
            ss >> rs >> lbl;

            if (!labels.count(lbl))
                asmError("Undefined label: " + lbl);

            uint32_t addr = labels.at(lbl);
            inst = encodeI(opcode, regNum(rs), 0, addr);
            
            std::stringstream ssAddr;
            ssAddr << std::hex << std::uppercase << std::setw(3) << std::setfill('0') << addr;
            annotatedLine += " -> PC=0x" + ssAddr.str();
        }
        else if (op == "J" || op == "JAL") {
            std::string lbl;
            ss >> lbl;
            if (!labels.count(lbl))
                asmError("Undefined label: " + lbl);

            uint32_t addr = labels.at(lbl);
            inst = encodeJ(opcode, addr);
            
            std::stringstream ssAddr;
            ssAddr << std::hex << std::uppercase << std::setw(3) << std::setfill('0') << addr;
            annotatedLine += " -> PC=0x" + ssAddr.str();
        }
        else if (op == "JALR") {
            std::string rs;
            ss >> rs;
            inst = encodeJ(opcode, regNum(rs));
        }
        else if (op == "JR") {
            std::string rs;
            ss >> rs;
            inst = encodeJ(opcode, regNum(rs));
        }
        else if (op == "NOP") {
            inst = 0;
        }
        else if (op == "PCH" || op == "PD" || op == "PDU") {
            std::string rs;
            ss >> rs;

            // encode register in 26-bit J-type field
            inst = encodeJ(opcode, regNum(rs));
        }
        else if (op == "GD" || op == "GDU") {
            std::string rd;
            ss >> rd;

            // encode register in 26-bit J-type field
            inst = encodeJ(opcode, regNum(rd));
        }

        codeMem.push_back(inst);
        codeText.push_back(annotatedLine);
    }

    /* ---------- WRITE MIF ---------- */
    auto writeMIF = [](const char* f,
                    const std::vector<uint32_t>& mem,
                    const std::vector<std::string>* text = nullptr) {

        std::ofstream out(f);
        out << "DEPTH = 1024;\nWIDTH = 32;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n";

        for (size_t i = 0; i < mem.size(); i++) {
            out << std::setw(3) << std::setfill('0') << std::hex << std::uppercase << i
                << " : " << std::setw(8) << mem[i] << ";";

            if (text && i < text->size()) {
                out << " -- " << (*text)[i];
            }

            out << "\n";
        }

        out << "END;\n";
    };

    std::vector<uint32_t> fullData = dataMem;
    fullData.insert(fullData.end(), constMem.begin(), constMem.end());

    writeMIF(argv[2], fullData);
    writeMIF(argv[3], codeMem, &codeText);

    std::cout << "Assembly complete.\n";
    return 0;
}

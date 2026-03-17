#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
#include <iomanip>
#include <cstdint>

constexpr int NUM_REGS = 32;
constexpr int MEM_SIZE = 1024;

/* ================= CPU STATE ================= */
struct CPU {
    uint32_t pc = 0;
    uint32_t R[NUM_REGS]{};
};

/* ================= INSTRUCTION FIELDS ================= */
inline uint32_t OPC(uint32_t i)   { return i >> 26; }
inline uint32_t RD(uint32_t i)    { return (i >> 21) & 0x1F; }
inline uint32_t RS1(uint32_t i)   { return (i >> 16) & 0x1F; }
inline uint32_t RS2(uint32_t i)   { return (i >> 11) & 0x1F; }
inline int16_t  IMM(uint32_t i)   { return i & 0xFFFF; }
inline uint32_t ADDR(uint32_t i)  { return i & 0x03FFFFFF; }

/* ================= LOAD MIF ================= */
std::vector<uint32_t> load_mif(const std::string& file) {
    std::ifstream in(file);
    if (!in) {
        std::cerr << "Cannot open " << file << "\n";
        exit(1);
    }

    std::vector<uint32_t> mem(MEM_SIZE, 0);
    std::string line;

    while (std::getline(in, line)) {
        if (line.find(':') == std::string::npos) continue;

        std::stringstream ss(line);
        std::string a, colon, d;
        ss >> a >> colon >> d;

        uint32_t addr = std::stoul(a, nullptr, 16);
        uint32_t data = std::stoul(d, nullptr, 16);
        mem[addr] = data;
    }
    return mem;
}

/* ================= MAIN ================= */
int main() {
    CPU cpu;
    auto code = load_mif("codeFactorial.mif");
    auto data = load_mif("dataFactorial.mif");

    std::cout << "=== DLX Simulation Start ===\n";

    const uint32_t MAX_STEPS = 10000;
    uint32_t steps = 0;

    while (cpu.pc < MEM_SIZE && steps++ < MAX_STEPS) {

        uint32_t prev_pc = cpu.pc;
        uint32_t inst = code[cpu.pc];
        uint32_t op   = OPC(inst);

        cpu.R[0] = 0;   // R0 hardwired to zero

        std::cout << "PC=" << std::setw(3) << cpu.pc
                  << " INST=0x" << std::hex << std::setw(8)
                  << std::setfill('0') << inst
                  << std::dec << std::setfill(' ') << "\n";

        switch (op) {

        case 0x00:  // NOP
            cpu.pc++;
            break;

        case 0x01:  // LW
            cpu.R[RD(inst)] =
                data[cpu.R[RS1(inst)] + IMM(inst)];
            cpu.pc++;
            break;

        case 0x02:  // SW
            data[cpu.R[RS1(inst)] + IMM(inst)] =
                cpu.R[RD(inst)];
            cpu.pc++;
            break;

        case 0x03:  // ADD
            cpu.R[RD(inst)] =
                cpu.R[RS1(inst)] + cpu.R[RS2(inst)];
            cpu.pc++;
            break;

        case 0x04:  // ADDI
            cpu.R[RD(inst)] =
                cpu.R[RS1(inst)] + IMM(inst);
            cpu.pc++;
            break;

        case 0x08:  // SUBI
            cpu.R[RD(inst)] =
                cpu.R[RS1(inst)] - IMM(inst);
            cpu.pc++;
            break;

        case 0x20:  // SLEI
            cpu.R[RD(inst)] =
                ((int32_t)cpu.R[RS1(inst)] <= IMM(inst)) ? 1 : 0;
            cpu.pc++;
            break;

        case 0x2C: { // BNEZ (absolute PC target)
            uint32_t target = inst & 0xFFFF;
            cpu.pc = (cpu.R[RD(inst)] != 0)
                        ? target
                        : cpu.pc + 1;
            break;
        }

        case 0x2D:  // J
            cpu.pc = ADDR(inst);
            break;

        case 0x2F:  // JAL
            cpu.R[31] = cpu.pc + 1;
            cpu.pc = ADDR(inst);
            break;

        case 0x2E: { // JR (FIXED SEMANTICS)
            uint32_t rs = ADDR(inst);   // register index
            cpu.pc = cpu.R[rs];
            break;
        }

        default:
            std::cerr << "Unknown opcode: 0x"
                      << std::hex << op << std::dec << "\n";
            return 1;
        }

        /* ===== TERMINATION: self-loop (done) ===== */
        if (cpu.pc == prev_pc) {
            std::cout << "Program reached terminal loop. Halting simulation.\n";
            break;
        }
    }

    std::cout << "\n=== Simulation Finished ===\n";
    std::cout << "Final f = " << data[1] << "\n";

    return 0;
}

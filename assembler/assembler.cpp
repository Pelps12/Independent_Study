#include <iostream>
#include <unordered_map>
#include <vector>
#include <bitset>
#include <regex>
#include <fstream>
#include "assembler.hpp"
#include <optional>
using namespace std;

typedef enum
{
    ALU = 0,
    JUMP = 1,
    BRANCH = 2,
    MEM = 3,
    NO_OP = 4,
    INT = 5,
    DATA = 6,
    MISC = 7
} command_type_enum;

struct Instruction_Details
{
    std::string op_type;
    bool immediate;
    int value;
};
struct Command
{
    command_type_enum op_type;
    optional<bool> immediate;
    optional<int> value;
};

struct Registers
{
    int value;
    bool special;
};

vector<string> getWords(string s, string delim)
{

    vector<string> res;
    string token = "";
    for (int i = 0; i < s.size(); i++)
    {
        bool flag = true;
        for (int j = 0; j < delim.size(); j++)
        {
            if (s[i + j] != delim[j])
                flag = false;
        }
        if (flag)
        {
            if (token.size() > 0)
            {
                res.push_back(token);
                token = "";
                i += delim.size() - 1;
            }
        }
        else
        {
            token += s[i];
        }
    }
    res.push_back(token);
    return res;
};

vector<string> getWordsNew(string str, string delim)
{
    // Create a stringstream object to str
    vector<string> res;
    regex del(delim);

    // Create a regex_token_iterator to split the string
    sregex_token_iterator it(str.begin(), str.end(), del, -1);

    // End iterator for the regex_token_iterator
    sregex_token_iterator end;

    // Iterating through each token
    while (it != end)
    {
        cout << "\"" << *it << "\"" << " ";
        res.push_back(*it);
        ++it;
    }
    return res;
};

int assemble(std::string input_file, std::string output_file)
{
    std::cout << "HELLO" << std::endl;
    unordered_map<string, Command> umap;
    unordered_map<string, Command> new_map;
    unordered_map<string, Registers> registers;
    unordered_map<string, int> jump_table;

    registers = {
        {"$r0", {0, false}},
        {"$r1", {1, false}},
        {"$r2", {2, false}},
        {"$r3", {3, false}},
        {"$r4", {4, false}},
        {"$r5", {5, false}},
        {"$r6", {6, false}},
        {"$r7", {7, false}},
        {"$r8", {8, false}},
        {"$r9", {9, false}},
        {"$r10", {10, false}},
        {"$r11", {11, false}},
        {"$r12", {12, false}},
        {"$r25", {25, false}},
        {"$r28", {28, false}},
        {"$r29", {29, true}},
        {"$r30", {30, true}},
        {"$r31", {31, true}},
        {"$axi_addr", {16, true}},
        {"$axi_rdata", {17, true}},
        {"$axi_wdata", {18, true}},
        {"$axi_status_to", {19, true}},
        {"$axi_status_from", {20, true}},
        {"$zero", {29, true}},
        {"$pc", {23, true}},
        {"$int_p", {30, true}},
        {"$temp", {31, false}},
        {"$p_state", {27, true}},
        {"$int_b_p", {28, true}},
        {"$sp", {30, true}},
        {"$curr_int_id", {25, true}},
        {"$lr", {26, true}}};

    umap = {
        {"add", {ALU, false, 0}},
        {"sub", {ALU, false, 1}},
        {"addi", {ALU, true, 0xa}},
        {"subi", {ALU, true, 0xb}},
        {"andi", {ALU, true, 0x13}},
        {"ori", {ALU, true, 0x14}},
        {"lw", {MEM, true, 0x07}},
        {"sw", {MEM, true, 0x08}},
        {"jump", {JUMP, true, 0x09}}, // JUMP and G-JUMP are very confusing. Jump should be jump-imm
        {"g_jump_imm", {JUMP, true, 0xc}},
        {"g_jump", {JUMP, false, 0xf}},
        {"beq", {BRANCH, false, 0x06}},
        {"bneq", {BRANCH, false, 0x18}},
        {"no-op", {NO_OP, false, 0xe}},
        {"int", {INT, false, 0x10}},
        {"sw_pc", {MEM, true, 0xd}},
        {"mov", {ALU, false, 0x12}},
        {"movi", {ALU, true, 0x15}},
        {"word", {DATA}},
        {"iret", {MISC, false, 0x17}},
        {"jump_l", {JUMP, true, 0x11}},
        {"btsli", {ALU, true, 0x19}},
        {"btsri", {ALU, true, 0x1a}}};

    int address;
    for (int pass = 1; pass < 3; ++pass)
    {
        ifstream file(input_file);
        ofstream out_file(output_file);

        string line;
        if (file.is_open())
        {
            // Read each line from the file and store it in the
            // 'line' variable.
            cout << endl;
            cout << "Pass: " << pass << endl;
            cout << "-------------------" << endl;
            address = 0;
            while (getline(file, line))
            {
                vector<string> split_by_comment = getWordsNew(line, "//");
                vector<string> tokens = getWordsNew(line, " ");

                std::cout << hex << address << " " << tokens.size() << split_by_comment.size() << endl;
                if (tokens.size() == 0)
                {
                    continue;
                }
                else
                {
                    string first_token = tokens[0];
                    bitset<32> result;

                    if (first_token == "section")
                    {
                        std::cout << tokens[1] << endl;
                        address = stoi(tokens[1], 0, 16);
                        std::cout << address << endl;
                        out_file << "@" << hex << address << endl;
                        continue;
                    }
                    else if (first_token.find(':') != std::string::npos)
                    {
                        // TO-D0
                        vector<string> label_words = getWords(first_token, ":");
                        string label = label_words[0];
                        std::cout << label << endl;
                        jump_table[label] = address;
                        continue;
                    }
                    else
                    {
                        auto it = umap.find(first_token);
                        if (it != umap.end())
                        {
                            Command op_code = it->second;
                            if (op_code.op_type != DATA && op_code.value.has_value() && op_code.immediate.has_value())
                            {
                                // std::cout << op_code.op_type << " " << op_code.immediate << std::endl;
                                if (op_code.op_type == ALU)
                                {
                                    cout << "IN ALU SECTION" << endl;
                                    if (tokens.size() < 3)
                                    {
                                        cout << "HMMM" << endl;
                                        invalid_argument("There should be three arguments");
                                    }
                                    else
                                    {
                                        cout << "IN OTHER ALU SECTION" << endl;
                                        bitset<5> op_code_bs = op_code.value.value();
                                        bitset<5> rs = (registers[tokens[1]].value);
                                        bitset<5> rt = (registers[tokens[2]].value);
                                        bitset<5> rd;
                                        bitset<17> imm;
                                        int index = first_token == "movi" ? 2 : 3;

                                        if (op_code.immediate.value())
                                        {
                                            rd = 0;
                                            if (tokens[index].substr(0, 2) == "0x")
                                            {
                                                imm = stoi(tokens[index], 0, 16);
                                            }
                                            else
                                            {
                                                imm = stoi(tokens[index]);
                                            }
                                            if (first_token == "movi")
                                            {
                                                rt = rs;
                                                rs = 0;
                                                result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                          (bitset<32>(rs.to_ulong() << 22)) |
                                                          (bitset<32>(rt.to_ulong() << 17)) |
                                                          (bitset<32>(imm.to_ulong() << 0)));
                                            }
                                            else
                                            {
                                                result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                          (bitset<32>(rs.to_ulong() << 22)) |
                                                          (bitset<32>(rt.to_ulong() << 17)) |
                                                          (bitset<32>(imm.to_ulong() << 0)));
                                            }
                                        }
                                        else
                                        {
                                            if (first_token == "mov")
                                            {
                                                rd = 0;
                                            }
                                            else
                                            {
                                                rd = registers[tokens[3]].value;
                                            }

                                            // FLIP FOR SEMANTIC CONSISTENCY
                                            result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                      (bitset<32>(rt.to_ulong() << 22)) |
                                                      (bitset<32>(rs.to_ulong() << 17)) |
                                                      (bitset<32>(rd.to_ulong() << 12)));
                                            cout << "In Move Section" << result << endl;
                                        }
                                    }
                                }
                                else if (op_code.op_type == MEM)
                                {
                                    if (first_token != "sw_pc")
                                    {
                                        bitset<5> op_code_bs = op_code.value.value();
                                        bitset<5> rb;
                                        bitset<17> imm;

                                        std::regex pattern(R"((\d+)\((\$\w+)\))");
                                        string second_token = tokens[1];

                                        std::smatch matches;
                                        if (std::regex_match(second_token, matches, pattern))
                                        {
                                            std::string offset = matches[1];        // "16"
                                            std::string register_name = matches[2]; // "r1";
                                            imm = stoi(offset);
                                            rb = registers[register_name].value;
                                        }
                                        else
                                        {
                                            throw invalid_argument("Not a matching sequence");
                                        }

                                        bitset<5> rd = registers[tokens[2]].value;

                                        result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                  (bitset<32>(rb.to_ulong() << 22)) |
                                                  (bitset<32>(rd.to_ulong() << 17)) |
                                                  (bitset<32>(imm.to_ulong() << 0)));
                                    }
                                    else
                                    {
                                        bitset<5> op_code_bs = op_code.value.value();
                                        bitset<5> rb;
                                        bitset<17> imm;

                                        std::regex pattern(R"((\d+)\((\$\w+)\))");
                                        string second_token = tokens[1];

                                        std::smatch matches;
                                        if (std::regex_match(second_token, matches, pattern))
                                        {
                                            std::string offset = matches[1];        // "16"
                                            std::string register_name = matches[2]; // "r1";
                                            imm = stoi(offset);
                                            rb = registers[register_name].value;
                                            // cout << register_name << endl;
                                        }
                                        else
                                        {
                                            throw invalid_argument("Not a matching sequence");
                                        }

                                        result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                  (bitset<32>(rb.to_ulong() << 22)) |
                                                  (bitset<32>(imm.to_ulong() << 0)));
                                    }
                                }
                                else if (op_code.op_type == JUMP)
                                {
                                    if (op_code.immediate.value())
                                    {
                                        bitset<5> op_code_bs = op_code.value.value();
                                        bitset<17> imm;
                                        string jump_label = tokens[1];
                                        cout << "Jump Label: " << jump_label << endl;
                                        int jump_address = jump_table[jump_label];

                                        if (jump_address != 0)
                                        {
                                            imm = jump_address;
                                        }
                                        else
                                        {
                                            if (pass == 1)
                                            {
                                                cout << "Missing in First Pass" << endl;
                                            }
                                            else
                                            {
                                                throw invalid_argument("Address not Found");
                                            }
                                        }

                                        result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                  (bitset<32>(imm.to_ulong() << 0)));
                                    }
                                    else
                                    {
                                        bitset<5> op_code_bs = op_code.value.value();
                                        bitset<5> rs = registers[tokens[1]].value;

                                        result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                                  (bitset<32>(rs.to_ulong() << 22)));
                                    }
                                }
                                else if (op_code.op_type == BRANCH)
                                {
                                    bitset<5> op_code_bs = op_code.value.value();
                                    bitset<5> rs = (registers[tokens[1]].value);
                                    bitset<5> rt = (registers[tokens[2]].value);
                                    bitset<17> imm;
                                    string jump_label = tokens[3];
                                    int branch_value = jump_table[jump_label] - address;

                                    if (jump_table[jump_label] != 0)
                                    {
                                        imm = branch_value;
                                    }
                                    else
                                    {
                                        if (pass == 1)
                                        {
                                            cout << "Missing in First Pass" << endl;
                                        }
                                        else
                                        {
                                            throw invalid_argument("Address not Found");
                                        }
                                    }

                                    result = ((bitset<32>(op_code_bs.to_ulong()) << 27) |
                                              (bitset<32>(rs.to_ulong()) << 22) |
                                              (bitset<32>(rt.to_ulong()) << 17) |
                                              (bitset<32>(imm.to_ulong() << 0)));
                                }
                                else if (op_code.op_type == NO_OP)
                                {
                                    bitset<5> op_code_bs = op_code.value.value();
                                    result = (bitset<32>(op_code_bs.to_ulong() << 27));
                                }
                                else if (op_code.op_type == INT)
                                {
                                    bitset<5> op_code_bs = op_code.value.value();
                                    result = (bitset<32>(op_code_bs.to_ulong() << 27) |
                                              bitset<32>(stoi(tokens[1], 0, 16)));
                                }
                                else if (op_code.op_type == MISC)
                                {
                                    bitset<5> op_code_bs = op_code.value.value();
                                    result = (bitset<32>(op_code_bs.to_ulong()) << 27);
                                }
                            }
                            else
                            {

                                if (tokens[1].substr(0, 2) == "0x")
                                {
                                    cout << "VALUE: " << stoi(tokens[1]) << endl;
                                    result = stoll(tokens[1], 0, 16);
                                }
                                else
                                {
                                    result = stoll(tokens[1]);
                                }
                            }
                            std::cout << hex << result.to_ulong() << "\n " << op_code.op_type << endl;

                            if (pass == 2)
                            {
                                out_file << hex << result.to_ulong() << endl;
                            }
                            address++;
                        }
                    }
                }
            }
            // Close the file stream once all lines have been
            // read.

            file.close();
            out_file.close();
        }
        else
        {
            // Print an error message to the standard error
            // stream if the file cannot be opened.
            cerr << "Unable to open file!" << endl;
        }
    }

    std::vector<std::string> instructions = {
        "start 0x100",
        "sub $r1 $r2 $r3",
        "addi $r1 $r1 100",
        "Loop:   "
        "addi $int_p $int_p 1",
        "lw 2($r0) $r3",
        "jump Loop",
        "g_jump $temp",
        "beq $r4 $r3 Loop_2",
        "Loop_2: ",
        "subi $int_p $int_p 1"};

    // std::cout << registers[getWords(instructions[0], " ")[3]].value<< std::endl;
    return 0;
}

#include "assembler.hpp"
using namespace std;
#include <stdexcept>
int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        throw std::invalid_argument("Not enough characters");
    }
    assemble(argv[1], argv[2]);
}
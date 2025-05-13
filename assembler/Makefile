TARGET = ./out

IDIR = .
SDIR = .
ODIR = ./obj

SRC = $(wildcard $(SDIR)/*.cpp)
OBJ = $(patsubst $(SDIR)/%.cpp,$(ODIR)/%.o,$(SRC))

CXX = g++
CXXFLAGS = -I$(IDIR) -Iinclude -g -O0 -std=c++17 -Wall

$(TARGET): $(OBJ)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(ODIR)/%.o: $(SDIR)/%.cpp
	@mkdir -p $(ODIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(TARGET)
	$(RM) -r $(ODIR)

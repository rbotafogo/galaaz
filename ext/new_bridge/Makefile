# Makefile for Galaaz Gatekeeper shared library
# Usage: make clean all

# R configuration
R_HOME := $(shell R RHOME)
R_CPPFLAGS := $(shell $(R_HOME)/bin/R CMD config --cppflags)
R_LIBS := $(shell $(R_HOME)/bin/R CMD config --ldflags)

# Rcpp configuration
RCPP_INCLUDE := $(shell $(R_HOME)/bin/Rscript -e "cat(system.file('include', package='Rcpp'))")
RCPP_CPPFLAGS := -I$(RCPP_INCLUDE)

# Compiler settings
CXX := $(shell $(R_HOME)/bin/R CMD config CXX)
CXXFLAGS := $(shell $(R_HOME)/bin/R CMD config CXXFLAGS)
CPPFLAGS := $(R_CPPFLAGS) $(RCPP_CPPFLAGS) -I.
# Core R library only (avoid system libs that may not be present)
LDFLAGS := -L$(R_HOME)/lib -lR -Wl,-rpath,$(R_HOME)/lib

# Target library
TARGET := galaaz_gatekeeper.so
SRC := galaaz_gatekeeper_phase1.cpp
OBJ := $(SRC:.cpp=.o)

.PHONY: all clean check

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CXX) -shared -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -fPIC -c $< -o $@

check: $(TARGET)
	@echo "Checking library..."
	@$(R_HOME)/bin/Rscript -e "dyn.load('$(TARGET)'); cat('Library loads successfully\n')"

clean:
	rm -f $(OBJ) $(TARGET)

# Development helpers
install: $(TARGET)
	@echo "Copying to galaaz lib directory..."
	mkdir -p ../../lib/new_bridge
	cp $(TARGET) ../../lib/new_bridge/

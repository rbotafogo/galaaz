# Makefile for Galaaz Gatekeeper shared library
# Usage: make clean all

# Prefer `R` / `Rscript` on PATH (Omarchy/Arch: RHOME may be /usr/lib64/R).
R_HOME := $(shell R RHOME)
R_CPPFLAGS := $(shell R CMD config --cppflags)
# Full linker flags from R (do NOT hardcode -L$(R_HOME)/lib — wrong on some Arch layouts).
R_LDFLAGS := $(shell R CMD config --ldflags)

# Rcpp configuration (needs R_LIBS_USER for user-library installs)
RCPP_INCLUDE := $(shell Rscript -e "cat(system.file('include', package='Rcpp'))")
RCPP_CPPFLAGS := -I$(RCPP_INCLUDE)

# Compiler settings
CXX := $(shell R CMD config CXX)
CXXFLAGS := $(shell R CMD config CXXFLAGS)
CPPFLAGS := $(R_CPPFLAGS) $(RCPP_CPPFLAGS) -I.
LDFLAGS := $(R_LDFLAGS) -Wl,-rpath,$(R_HOME)/lib

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
	@Rscript -e "dyn.load('$(TARGET)'); cat('Library loads successfully\n')"

clean:
	rm -f $(OBJ) $(TARGET)

# Development helpers
install: $(TARGET)
	@echo "Copying to galaaz lib directory..."
	mkdir -p ../../lib/new_bridge
	cp $(TARGET) ../../lib/new_bridge/

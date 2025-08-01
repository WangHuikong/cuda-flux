# CUDA Cache Bandwidth Test Makefile

# Compiler and flags
NVCC = nvcc
CXX = g++
CXXFLAGS = -O3 -std=c++11 -pthread
NVCCFLAGS = -arch=sm_80 -O3 -std=c++11

# Target executables
TARGET_GPU = cache_bandwidth_test
TARGET_CPU = cache_bandwidth_test_cpu

# Source files
SOURCES_GPU = cache_bandwidth_test.cu
SOURCES_CPU = cache_bandwidth_test_cpu.cpp

# Default target - check environment and build appropriate version
all: check-env

# Check environment and build appropriate version
check-env:
	@if command -v nvcc >/dev/null 2>&1; then \
		echo "NVCC found, building GPU version..."; \
		$(MAKE) gpu; \
	else \
		echo "NVCC not found, building CPU simulation..."; \
		$(MAKE) cpu; \
	fi

# Build GPU version
gpu: $(TARGET_GPU)

# Build CPU version
cpu: $(TARGET_CPU)

# Build the GPU executable
$(TARGET_GPU): $(SOURCES_GPU)
	$(NVCC) $(NVCCFLAGS) -o $(TARGET_GPU) $(SOURCES_GPU)

# Build the CPU executable
$(TARGET_CPU): $(SOURCES_CPU)
	$(CXX) $(CXXFLAGS) -o $(TARGET_CPU) $(SOURCES_CPU)

# Clean build artifacts
clean:
	rm -f $(TARGET_GPU) $(TARGET_CPU)

# Run the appropriate test
run: 
	@if [ -f $(TARGET_GPU) ]; then \
		echo "Running GPU version..."; \
		./$(TARGET_GPU); \
	elif [ -f $(TARGET_CPU) ]; then \
		echo "Running CPU simulation..."; \
		./$(TARGET_CPU); \
	else \
		echo "No executable found. Run 'make' first."; \
	fi

# Install CUDA (if needed)
install-cuda:
	@echo "Please install CUDA Toolkit 11.0 or later"
	@echo "For Ubuntu/Debian: sudo apt install nvidia-cuda-toolkit"
	@echo "Or download from: https://developer.nvidia.com/cuda-downloads"

# Check CUDA installation
check-cuda:
	@which nvcc > /dev/null && echo "NVCC found: $$(which nvcc)" || echo "NVCC not found. Please install CUDA Toolkit."
	@nvidia-smi > /dev/null 2>&1 && echo "NVIDIA GPU detected" || echo "No NVIDIA GPU detected or driver not installed"

.PHONY: all clean run install-cuda check-cuda
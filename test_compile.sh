#!/bin/bash

# CUDA Cache Bandwidth Test Compilation Script

echo "=== CUDA Cache Bandwidth Test Compilation ==="
echo "Checking CUDA installation..."

# 检查nvcc是否可用
if ! command -v nvcc &> /dev/null; then
    echo "Error: nvcc not found. Please install CUDA Toolkit."
    exit 1
fi

echo "CUDA version: $(nvcc --version | head -n1)"

# 检查GPU是否可用
echo "Checking GPU availability..."
if ! nvidia-smi &> /dev/null; then
    echo "Warning: nvidia-smi not available. GPU tests may not work."
else
    echo "GPU detected:"
    nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv,noheader
fi

echo ""
echo "Compiling basic cache bandwidth test..."
make clean
make cuda_cache_bandwidth

if [ $? -eq 0 ]; then
    echo "✓ Basic program compiled successfully"
else
    echo "✗ Basic program compilation failed"
    exit 1
fi

echo ""
echo "Compiling advanced cache bandwidth test..."
make advanced_cache_test

if [ $? -eq 0 ]; then
    echo "✓ Advanced program compiled successfully"
else
    echo "✗ Advanced program compilation failed"
    exit 1
fi

echo ""
echo "=== Compilation Summary ==="
echo "✓ Both programs compiled successfully"
echo ""
echo "To run the basic test:"
echo "  ./cuda_cache_bandwidth"
echo ""
echo "To run the advanced test:"
echo "  ./advanced_cache_test"
echo ""
echo "Or use make targets:"
echo "  make run           # Run basic test"
echo "  make run-advanced  # Run advanced test"
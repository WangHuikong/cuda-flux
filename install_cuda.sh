#!/bin/bash

# CUDA Installation Script for Ubuntu/Debian
# This script helps install CUDA Toolkit for the cache bandwidth test

set -e

echo "=== CUDA Toolkit Installation Script ==="
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Please don't run this script as root. Use your regular user account."
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "Cannot detect OS version"
    exit 1
fi

echo "Detected OS: $OS $VER"

# Check for NVIDIA GPU
if ! command -v nvidia-smi &> /dev/null; then
    echo "Warning: nvidia-smi not found. Make sure NVIDIA drivers are installed."
    echo "You can install drivers with: sudo apt install nvidia-driver-470"
    echo
fi

# Function to install CUDA on Ubuntu
install_cuda_ubuntu() {
    echo "Installing CUDA Toolkit on Ubuntu..."
    
    # Add NVIDIA package repositories
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt-get update
    
    # Install CUDA Toolkit
    sudo apt-get -y install cuda-toolkit-11-8
    
    # Add CUDA to PATH
    echo 'export PATH=/usr/local/cuda-11.8/bin${PATH:+:${PATH}}' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    
    echo "CUDA installation completed!"
    echo "Please run 'source ~/.bashrc' or restart your terminal"
}

# Function to install CUDA via package manager (simpler but may be older version)
install_cuda_simple() {
    echo "Installing CUDA via package manager..."
    sudo apt update
    sudo apt install -y nvidia-cuda-toolkit
    echo "CUDA installation completed!"
}

echo "Choose installation method:"
echo "1) Full CUDA Toolkit (recommended, latest version)"
echo "2) Simple installation via apt (may be older version)"
echo "3) Manual installation instructions"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        if [[ "$OS" == *"Ubuntu"* ]]; then
            install_cuda_ubuntu
        else
            echo "Full installation script only supports Ubuntu. Please choose option 2 or 3."
            exit 1
        fi
        ;;
    2)
        install_cuda_simple
        ;;
    3)
        echo
        echo "=== Manual Installation Instructions ==="
        echo
        echo "1. Visit: https://developer.nvidia.com/cuda-downloads"
        echo "2. Select your OS, architecture, and distribution"
        echo "3. Follow the installation instructions provided"
        echo
        echo "For Ubuntu 20.04 x86_64:"
        echo "wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run"
        echo "sudo sh cuda_11.8.0_520.61.05_linux.run"
        echo
        echo "After installation, add to ~/.bashrc:"
        echo "export PATH=/usr/local/cuda/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo
echo "After CUDA installation, you can:"
echo "1. Verify installation: nvcc --version"
echo "2. Check GPU: nvidia-smi"
echo "3. Compile the test: make"
echo "4. Run the test: make run"
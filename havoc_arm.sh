#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ENDCOLOR='\033[0m'

 echo -e "${BLUE}_  _   ___   _____   ___   ___ ___  ___     _   ___ __  __ "
 echo -e "${BLUE}| || | /_\ \ / / _ \ / __| | __/ _ \| _ \   /_\ | _ \  \/  |"
 echo -e "${BLUE}| __ |/ _ \ V / (_) | (__  | _| (_) |   /  / _ \|   / |\/| |"
 echo -e "${BLUE}|_||_/_/ \_\_/ \___/ \___| |_| \___/|_|_\ /_/ \_\_|_\_|  |_|"
 echo -e "${BLUE}                                                            "

echo -e "${GREEN} Created by KR45 (ezio)"

echo -e "${BLUE} Checking packages"

# amd64 package
packages=("qemu-user-static" "binfmt-support")

# Function to check if a package is installed
check_package() {
    dpkg -s "$1" &> /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Package $1 is installed.${ENDCOLOR}"
    else
        echo -e "${RED}Package $1 is not installed.${ENDCOLOR}"
        echo -e "${GREEN} Installing $1"
        sudo apt install -y qemu-user-static binfmt-support
    fi
}

# Iterate through the list of packages and check each one
for package in "${packages[@]}"
do
    check_package "$package"
done

echo -e "${BLUE}Adding amd64 requirements"

if dpkg --print-foreign-architectures | grep -q "amd64"; then
    echo -e "${GREEN}amd64 architecture successfully added.${ENDCOLOR}"
else
    echo -e "${RED}Adding amd64 architecture.${ENDCOLOR}"
    sudo dpkg --add-architecture amd64
    sudo apt update
    echo -e "${GREEN}Adding Libraries"
    sudo apt install libc6:amd64
    exit 1
fi

echo -e "${BLUE} HAVOC"

#installing requried packages 

hav=(
    "git"
    "build-essential"
    "apt-utils"
    "cmake"
    "libfontconfig1"
    "libglu1-mesa-dev"
    "libgtest-dev"
    "libspdlog-dev"
    "libboost-all-dev"
    "libncurses5-dev"
    "libgdbm-dev"
    "libssl-dev"
    "libreadline-dev"
    "libffi-dev"
    "libsqlite3-dev"
    "libbz2-dev"
    "mesa-common-dev"
    "qtbase5-dev"
    "qtchooser"
    "qt5-qmake"
    "qtbase5-dev-tools"
    "libqt5websockets5"
    "libqt5websockets5-dev"
    "qtdeclarative5-dev"
    "golang-go"
    "qtbase5-dev"
    "libqt5websockets5-dev"
    "python3-dev"
    "libboost-all-dev"
    "mingw-w64"
    "nasm"
    "bc"
)

check_package() {
    dpkg -s "$1" &> /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Package $1 is already installed.${ENDCOLOR}"
    else
        echo -e "${RED}Package $1 is not installed."
        echo -e "${GREEN}Installing...${ENDCOLOR}"
        sudo apt-get install -y "$1"
    fi
}

echo -e "${BLUE}Checking package installations${ENDCOLOR}"

# Iterate through the list of packages and check/install each one
for package in "${hav[@]}"
do
    check_package "$package"
done

#checking python version

install_pyenv() {
    # Check if pyenv is already installed and configured in .zshrc
    if command -v pyenv >/dev/null 2>&1 && grep -q 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc; then
        echo -e "${BLUE} pyenv is already installed and configured. Skipping installation."
        return 0
    fi

    echo -e "${BLUE} Installing pyenv and configuring shell."

    # Install pyenv using curl
    curl https://pyenv.run | bash

    # Add pyenv configuration to .zshrc if it doesn't already exist
    if ! grep -q 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc
        source .zshrc
    fi

    # Ensure the shell is properly set and reload it
    [ -z "$SHELL" ] && SHELL=/usr/bin/zsh
    exec $SHELL
}

py=$(python3 --version 2>&1 | awk '{print $2}')
required_version="3.10"

if [ "$py_version" == "$required_version" ]; then
    echo -e "${GREEN}Python version is $required_version. Good to go!!!${ENDCOLOR}"
else
    echo -e "${BLUE}Current Python version is $py_version.${ENDCOLOR}"
    echo -e "${BLUE}Do you want to install Python 3.10? (y/n)${ENDCOLOR}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        install_pyenv
    else
        echo -e "${RED}Python 3.10 installation skipped.${ENDCOLOR}"
    fi
fi

#clonning havoc
# Clone Havoc repository if not already present
if [ ! -d "Havoc" ]; then
    git clone https://github.com/HavocFramework/Havoc.git
fi

cd Havoc

# Installing Havoc Go dependencies
cd teamserver
go mod download golang.org/x/sys
go mod download github.com/ugorji/go
cd ..

# Check if the teamserver binary (or the target build file) already exists
if [ ! -f "Havoc/havoc" ]; then
    echo "Building teamserver binary..."
    make ts-build
else
    echo "Teamserver binary already exists, skipping build."
fi


# Build the client binary
build_client_binary() {
    echo -e "${BLUE}Building the client binary...${ENDCOLOR}"
    make client-build

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Client binary built successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Error: Failed to build the client binary.${ENDCOLOR}"
    fi
}

# Function to check system requirements
check_system_requirements() {
    # Get the total amount of RAM in GB
    total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 1024}')

    # Get the number of CPU cores
    cpu_cores=$(nproc)

    # Print system information
    echo -e "${BLUE}System Information:${ENDCOLOR}"
    echo -e "Total RAM: ${total_ram} GB"
    echo -e "CPU Cores: ${cpu_cores}"

    # Check if RAM is less than 4 GB
    if (( $(echo "$total_ram < 4" | bc -l) )); then
        echo -e "${RED}Warning: RAM is less than 4 GB. Building may be slow.${ENDCOLOR}"
        build_client_binary
    fi

    # Check if CPU cores are less than 4
    if [ "$cpu_cores" -lt 4 ]; then
        echo -e "${RED}Warning: Less than 4 CPU cores detected. Building may be slow.${ENDCOLOR}"
        build_client_binary
    fi
}

# Check system requirements
check_system_requirements








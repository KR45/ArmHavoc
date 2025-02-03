#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ENDCOLOR='\033[0m'

function print_blue () {
    echo -e "${BLUE}${1}${ENDCOLOR}"
}

function print_green () {
    echo -e "${BLUE}${1}${ENDCOLOR}"
}

function print_red () {
    echo -e "${BLUE}${1}${ENDCOLOR}"
}

print_blue "_  _   ___   _____   ___   ___ ___  ___     _   ___ __  __ "
print_blue "| || | /_\ \ / / _ \ / __| | __/ _ \| _ \   /_\ | _ \  \/  |"
print_blue "| __ |/ _ \ V / (_) | (__  | _| (_) |   /  / _ \|   / |\/| |"
print_blue "|_||_/_/ \_\_/ \___/ \___| |_| \___/|_|_\ /_/ \_\_|_\_|  |_|"
print_blue "                                                            "

print_green "Created by KR45 (ezio)"

# Ask for sudo password if not already cached; and check if user has sudo rights
sudo -v &>/dev/null

#installing requried packages 
print_blue "Checking packages"
apt_packages=(
    "qemu-user-static" 
    "binfmt-support"
    "git"
    "build-essential"
    "apt-utils"
    "cmake"
    "libfontconfig1"
    "libglu1-mesa-dev"
    "libgtest-dev"
    "libspdlog-dev"
    "libboost-all-dev"
    #"libncurses5-dev" uncomment this if you get issue for new version below is compitable
    "libncurses-dev"
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

function check_package() {
    dpkg -s "${1}" &> /dev/null

    if [ $? -eq 0 ]; 
    then
       print_green "Package ${1} is already installed."
    else
        print_red "Package ${1} is not installed."
        print_blue "Installing..."
        sudo apt-get install -y "${1}"
    fi
}

function install_pyenv() {
    # Check if pyenv is already installed and configured in .zshrc
    if command -v pyenv >/dev/null 2>&1 && grep -q 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc; then
        print_blue "pyenv is already installed and configured. Skipping installation."
        return 0
    fi

    print_blue "Installing pyenv and configuring shell."

    # Install pyenv using curl
    curl -fsSL "https://pyenv.run" | bash

    # Add pyenv configuration to .zshrc if it doesn't already exist
    if [[ ! $(grep -q 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc) ]]; 
    then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc
        #exporting to current shell session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
    fi
}

function build_teamserver_binary () {
    # Installing Havoc Go dependencies
    cd teamserver
    go mod tidy
    go mod download golang.org/x/sys
    go mod download github.com/ugorji/go
    cd ..
    make ts-build
    if [ ${?} -eq 0 ]; 
    then
        print_green "Teamserver binary built successfully."
    else
        print_blue "Teamserver binary already exists, skipping build."
    fi
}

# Build the client binary
function build_client_binary () {
    print_blue "Building the client binary..."
    make client-build

    if [ ${?} -eq 0 ]; then
        print_green "Client binary built successfully."
    else
        print_red "Error: Failed to build the client binary."
    fi
}

# Function to check system requirements and build binaries
function check_system_requirements_and_build () {
    # Get the total amount of RAM in GB
    total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 1024}')

    # Get the number of CPU cores
    cpu_cores=$(nproc)

    # Print system information
    print_blue "System Information:"
    echo -e "Total RAM: ${total_ram} GB"
    echo -e "CPU Cores: ${cpu_cores}"

    # Check if RAM is less than 4 GB or CPU cores are less than 4
    if (( $(echo "$total_ram < 4" | bc -l) )) || [ "$cpu_cores" -lt 4 ]; 
    then
        if (( $(echo "$total_ram < 4" | bc -l) )); 
        then
            print_red "Warning: RAM is less than 4 GB. Building may be slow."
        fi

        if [ "$cpu_cores" -lt 4 ]; 
        then
            print_red "Warning: Less than 4 CPU cores detected. Building may be slow."
        fi

        print_blue " Adding amd64 requirements"

        if dpkg --print-foreign-architectures | grep -q "amd64"; then
            print_green "amd64 architecture successfully added."
        else
            print_red "Adding amd64 architecture."
            sudo dpkg --add-architecture amd64
            sudo apt update
            print_green "Adding Libraries"
            sudo apt install libc6:amd64
            exit 1
        fi

        print_blue "Checking package installations"

        # Iterate through the list of packages and check/install each one
        for package in "${apt_packages[@]}";
        do
            check_package "${package}"
        done

        #checking python version
        py=$(python3 --version 2>&1 | awk '{print $2}')
        required_version="3.10"
        if command -v pyenv >/dev/null 2>&1; 
        then
            print_green "pyenv is already installed. Skipping installation."
        else
            if [ "$py" = "$required_version" ]; 
            then
                print_green "Python version is $required_version. Good to go!!!"
            else
                print_blue "Current Python version is $py_version."
                print_blue "Do you want to install Python 3.10? (y/n)"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; 
                then
                    install_pyenv
                else
                    print_red "Python 3.10 installation skipped."
                fi
            fi
        fi

        # Clone Havoc repository if not already present
        if [ ! -d "Havoc" ]; 
        then
            git clone --recurse -b dev https://github.com/HavocFramework/Havoc.git Havoc
        fi

        cd Havoc

        # Check if the teamserver binary (or the target build file) already exists
        if [ ! -f "Havoc/havoc" ];
        then
            print_blue "Building teamserver binary..."
            build_teamserver_binary
        fi

        # Build client binary only if it doesn't exist
        if [ ! -f "Havoc/client/Havoc" ]; 
        then
            print_blue "Building client binary..."
            build_client_binary
        else
            print_blue "Client binary already exists, skipping build."
        fi
    fi
}

# Check system requirements
check_system_requirements_and_build

#!/bin/bash

# Set mount directory
MOUNT_DIR="/inspector/home"

# Check if the MOUNT_DIR directory is a mount point
if ! mountpoint -q "$MOUNT_DIR"; then
    echo "ERROR: $MOUNT_DIR is not mounted!"
    exit 1
fi

cd $MOUNT_DIR

# Navigate to the contract directory if defined
if [ "${CONTRACT_DIR}" ]; then
    # Verify that the contract directory exists
    if [ ! -d "${CONTRACT_DIR}" ]; then
        echo "ERROR: Contract directory ${CONTRACT_DIR} does not exist"
        exit 1
    fi

    # Navigate to the contract directory only if it's not the root
    cd ${CONTRACT_DIR}
    echo "Current directory: $(pwd)"
    # Current directory files
    ls -la
fi

# Check if the Cargo.toml file exists
if [ ! -f "Cargo.toml" ]; then
    echo "ERROR: Cargo.toml file does not exist"
    exit 1
fi

RUST_VERSION=$(sed -n '/\[package\]/,/^$/{/rust-version = /{s/rust-version = "\(.*\)"/\1/p;}}' Cargo.toml) 

# If rust version is not found in Cargo.toml, set it to the default version
if [ -z "$RUST_VERSION" ]; then
    RUST_VERSION="beta"
fi
echo "Required Rust version: $RUST_VERSION"

# Installing rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && . $HOME/.cargo/env

# Verify that rustup was installed
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install rustup"
    exit 1
fi

# Install the required rust version
rustup install $RUST_VERSION

# Verify that rust was installed
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install rust"
    exit 1
fi

# Set the default rust version
rustup default $RUST_VERSION

# Verify that rust was installed
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set the default rust version"
    exit 1
fi

# Add the cargo bin directory to the PATH
PATH="/root/.cargo/bin:${PATH}"

# Add the wasm32-unknown-unknown target
rustup target add wasm32-unknown-unknown

# Verify that wasm32-unknown-unknown target was added
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to add wasm32-unknown-unknown target"
    exit 1
fi

# Install wasm-opt
wget https://github.com/WebAssembly/binaryen/releases/download/version_101/binaryen-version_101-x86_64-linux.tar.gz && \
    tar -xzf binaryen-version_101-x86_64-linux.tar.gz && \
    cp binaryen-version_101/bin/wasm-opt /usr/local/bin/ && \
    rm -rf binaryen-version_101 binaryen-version_101-x86_64-linux.tar.gz

# Verify that wasm-opt was installed
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install wasm-opt"
    exit 1
fi

echo "Rustc Version:" $(rustc --version) && echo "Cargo Version:" $(cargo --version)

# Build the project with cargo for wasm32-unknown-unknown target
cargo build --target wasm32-unknown-unknown --release

# Verify that the build was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build the project"
    exit 1
fi

echo "Rustc Version:" $(rustc --version) && echo "Cargo Version:" $(cargo --version)

# Check if the Cargo.toml file exists
if [ ! -f "Cargo.toml" ]; then
    echo "ERROR: Cargo.toml file does not exist"
    exit 1
fi

# Get the target directory
TARGET_DIR=$(cargo metadata --format-version=1 --no-deps | jq -r ".target_directory")

# Verify that the target directory exists
if [ ! -d "${TARGET_DIR}" ]; then
    echo "ERROR: Target directory ${TARGET_DIR} does not exist"
    exit 1
fi

# Create the release directory
mkdir -p ${MOUNT_DIR}/release

# Verify that the release directory was created
if [ ! -d "${MOUNT_DIR}/release" ]; then
    echo "ERROR: Failed to create the release directory"
    exit 1
fi

# Get the package name and version
PACKAGE_NAME=$(grep -m1 '^name =' Cargo.toml | sed -E 's/^name = "(.*)"$/\1/')
PACKAGE_VERSION=$(grep -m1 '^version =' Cargo.toml | sed -E 's/^version = "(.*)"$/\1/')

# Verify that the package name and version were found
if [ -z "$PACKAGE_NAME" ] || [ -z "$PACKAGE_VERSION" ]; then
    echo "ERROR: Failed to get the package name and version"
    exit 1
fi

WASM_FILE_NAME="${PACKAGE_NAME}_v${PACKAGE_VERSION}.wasm"

# Find the .wasm file and copy it as unoptimized.wasm for hash calculation
find ${TARGET_DIR}/wasm32-unknown-unknown/release -name "*.wasm" -exec cp {} ${MOUNT_DIR}/release/${WASM_FILE_NAME} \;

# Verify that the unoptimized.wasm file exists
if [ ! -f "$MOUNT_DIR/release/${WASM_FILE_NAME}" ]; then
    echo "ERROR: unoptimized.wasm file does not exist"
    exit 1
fi

# Navigate to the release directory
cd ${MOUNT_DIR}/release

# Optimize the WASM file
wasm-opt -Oz ${WASM_FILE_NAME} -o ${WASM_FILE_NAME}

# Verify that the optimized.wasm file exists
if [ ! -f "${MOUNT_DIR}/release/${WASM_FILE_NAME}" ]; then
    echo "ERROR: optimized.wasm file does not exist"
    exit 1
fi
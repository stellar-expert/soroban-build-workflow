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

# Print Rust version
rustc --version

# Print Cargo version
cargo --version

# Print Soroban version
soroban --version

# Check if the Cargo.toml file exists
if [ ! -f "Cargo.toml" ]; then
    echo "ERROR: Cargo.toml file does not exist"
    exit 1
fi

# Build the contract
soroban contract build

# Verify that the build was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build the project"
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
soroban contract optimize --wasm ${WASM_FILE_NAME} --wasm-out ${WASM_FILE_NAME}

# Verify that the optimized.wasm file exists
if [ ! -f "${MOUNT_DIR}/release/${WASM_FILE_NAME}" ]; then
    echo "ERROR: optimized.wasm file does not exist"
    exit 1
fi
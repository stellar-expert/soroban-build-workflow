#!/bin/bash

# Set mount directory
MOUNT_DIR="/inspector/home"

# Check if the MOUNT_DIR directory is a mount point
if ! mountpoint -q "$MOUNT_DIR"; then
    echo "ERROR: $MOUNT_DIR is not mounted!"
    exit 1
fi

cd $MOUNT_DIR

# Check if the RELATIVE_PATH is defined
if [ "$RELATIVE_PATH" ]; then
    # Change the working directory
    cd $RELATIVE_PATH
fi

# Check if the MAKE_TARGET is defined
if [ "$MAKE_TARGET" ]; then
    # Run the make command
    make $MAKE_TARGET
    if [ $? -eq 0 ]; then
        echo "Make completed successfully."
    else
        echo "Make failed."
        exit 1
    fi
fi

# Print Rust version
rustc --version

# Print Cargo version
cargo --version

# Print Stellar version
stellar --version

# Check if the Cargo.toml file exists
if [ ! -f "Cargo.toml" ]; then
    echo "ERROR: Cargo.toml file does not exist"
    exit 1
fi

# Create output directory
OUTPUT="${MOUNT_DIR}/$(uuidgen)"
mkdir -p ${OUTPUT}



# Get metadata
CARGO_METADATA=$(cargo metadata --format-version=1 --no-deps)
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get the package metadata"
    exit 1
fi

# Check if the PACKAGE is defined add it to the build command
if [ "$PACKAGE" ]; then
    stellar contract build --package $PACKAGE --out-dir ${OUTPUT}
    # Set the package name to the provided package name
    PACKAGE_NAME=$PACKAGE
else
    # Get the package name from the Cargo.toml file
    PACKAGE_NAME=$(grep -m1 '^name =' Cargo.toml | cut -d '"' -f2)
    stellar contract build --out-dir ${OUTPUT}
fi

# Verify that the build was successful
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build the project"
    exit 1
fi

# Verify that the package name and version were found
if [ -z "$PACKAGE_NAME" ]; then
    echo "ERROR: Failed to get the package name"
    exit 1
fi

# Get the package version
PACKAGE_VERSION=$(echo "$CARGO_METADATA" | jq '.packages[] | select(.name == "'"${PACKAGE_NAME}"'") | .version' | sed -e 's/"//g')
if [ -z "$PACKAGE_VERSION" ]; then
    echo "ERROR: Failed to get the package version"
    exit 1
fi

WASM_FILE_NAME="${PACKAGE_NAME}_v${PACKAGE_VERSION}.wasm"

RELEASE_DIR="${MOUNT_DIR}/compilation_workflow_release"

# Remove the release directory if it exists, to avoid conflicts
if [ -d "${RELEASE_DIR}" ]; then
    rm -rf ${RELEASE_DIR}
fi

# Create the release directory
mkdir -p ${RELEASE_DIR}

# Verify that the release directory was created
if [ ! -d "${RELEASE_DIR}" ]; then
    echo "ERROR: Failed to create the release directory"
    exit 1
fi

# Find the .wasm file and copy it as unoptimized.wasm for hash calculation
find ${OUTPUT} -name "*.wasm" -exec cp {} ${RELEASE_DIR}/${WASM_FILE_NAME} \;

# Verify that the unoptimized.wasm file exists
if [ ! -f "${RELEASE_DIR}/${WASM_FILE_NAME}" ]; then
    echo "ERROR: unoptimized.wasm file does not exist"
    exit 1
fi

# Navigate to the release directory
cd ${RELEASE_DIR}

# Optimize the WASM file
stellar contract optimize --wasm ${WASM_FILE_NAME} --wasm-out ${WASM_FILE_NAME}

# Verify that the optimized.wasm file exists
if [ ! -f "${RELEASE_DIR}/${WASM_FILE_NAME}" ]; then
    echo "ERROR: wasm file doesn't exist"
    exit 1
fi

# Get the CLI version
CLI_VERSION=$(stellar --version | grep -oP 'stellar \K\S+')

# Calculate the SHA256 hash of the wasm file
WASM_FILE_SHA256=$(sha256sum $WASM_FILE_NAME | cut -d ' ' -f 1)

JSON_FILE="${RELEASE_DIR}/compilation_info.json"
jq -n --arg PACKAGE_NAME "$PACKAGE_NAME" \
       --arg PACKAGE_VERSION "$PACKAGE_VERSION" \
       --arg CLI_VERSION "$CLI_VERSION" \
       --arg WASM_FILE_NAME "$WASM_FILE_NAME" \
       --arg WASM_FILE_SHA256 "$WASM_FILE_SHA256" \
       '{ 
            packageName: $PACKAGE_NAME, 
            packageVersion: $PACKAGE_VERSION, 
            cliVersion: $CLI_VERSION, 
            wasmFileName: $WASM_FILE_NAME,
            wasmHash: $WASM_FILE_SHA256
       }' > "$JSON_FILE"
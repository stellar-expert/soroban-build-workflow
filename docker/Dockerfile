# Start from an Ubuntu base image
FROM ubuntu:20.04

# Disable prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up working directory
WORKDIR /inspector

# Install packages
RUN apt-get update && \
    apt-get install -y git curl wget jq build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust's cargo bin directory to your PATH
ENV PATH="${PATH}:/root/.cargo/bin"

# Install the wasm32-unknown-unknown target
RUN rustup target add wasm32-unknown-unknown

# Install soroban-cli 
RUN cargo install --locked soroban-cli --features opt

# Print the version of rustc
RUN rustc --version

# Print the version of cargo
RUN cargo --version

# Print the version of soroban-cli
RUN soroban --version

# Specify the contract directory
ENV CONTRACT_DIR=${CONTRACT_DIR}

# Copy entrypoint script
COPY /entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Start from an Ubuntu base image
FROM ubuntu:20.04

# Disable prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up working directory
WORKDIR /inspector

# Install packages
RUN apt-get update && \
    apt-get install -y git curl wget jq build-essential uuid-runtime && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust's cargo bin directory to your PATH
ENV PATH="${PATH}:/root/.cargo/bin"

# Define the version argument for rustc with a default value
ARG RUST_VERSION=""

# Install the specified version of rustc
RUN if [ "$RUST_VERSION" ]; then \
         rustup install "$RUST_VERSION"; \
         rustup default "$RUST_VERSION"; \
       fi

# Install the wasm32-unknown-unknown target
RUN rustup target add wasm32-unknown-unknown

# Define the version argument for stellar-cli with a default value
ARG STELLAR_CLI_VERSION=""

# Install stellar-cli 
RUN if [ -z "$STELLAR_CLI_VERSION" ]; then \
         cargo install --locked stellar-cli --features opt; \
       else \
         cargo install --locked stellar-cli --features opt --version $STELLAR_CLI_VERSION; \
       fi

# Print the version of rustc
RUN rustc --version

# Print the version of cargo
RUN cargo --version

# Print the version of stellar-cli
RUN stellar --version

# Specify the package to build
ENV PACKAGE=${PACKAGE}

# Specify the make target
ENV MAKE_TARGET=${MAKE_TARGET}

# Specify the working directory
ENV RELATIVE_PATH=${RELATIVE_PATH}

# Specify the repo
ENV REPO=${REPO}

# Specify home domain
ENV HOME_DOMAIN=${HOME_DOMAIN}

# Copy entrypoint script
COPY /entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
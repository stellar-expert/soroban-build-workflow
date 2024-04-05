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

# Specify the contract directory
ENV CONTRACT_DIR=${CONTRACT_DIR}

# Copy entrypoint script
COPY /entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
FROM jetpackio/devbox:latest

# Install additional system dependencies
USER root:root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        curl \
        git \
        jq \
        sudo \
        redis-tools \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Set up workspace directory
WORKDIR /code
RUN mkdir -p /code && chown ${DEVBOX_USER}:${DEVBOX_USER} /code

# Create workspace directories
RUN mkdir -p /code/workspace/{artifacts,cache,db,logging,secrets,tracing,config,locks,tmp,go} \
    && chown -R ${DEVBOX_USER}:${DEVBOX_USER} /code/workspace

# Switch to devbox user
USER ${DEVBOX_USER}:${DEVBOX_USER}

# Copy devbox configuration
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.json devbox.json
COPY --chown=${DEVBOX_USER}:${DEVBOX_USER} devbox.lock devbox.lock

# Install devbox packages
RUN devbox install && \
    devbox run -- echo "Devbox packages installed successfully" && \
    nix-store --gc && \
    nix-store --optimise

# Set up shell environment
RUN devbox shellenv --init-hook >> ~/.profile && \
    echo 'eval "$(devbox shellenv)"' >> ~/.bashrc

# Configure git
RUN git config --global --add safe.directory /code

# Expose port
EXPOSE 8000

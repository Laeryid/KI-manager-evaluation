FROM node:22-bookworm-slim

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl dos2unix \
    python3 python3-venv python3-pip \
    make g++ \
    fd-find ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for fd (Debian calls it fdfind)
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Install Pi globally (official package is @earendil-works/pi-coding-agent)
RUN npm install -g @earendil-works/pi-coding-agent@latest

# Copy and apply OpenRouter stability & pacing patch
COPY patch_pi.py /patch_pi.py
RUN python3 /patch_pi.py && rm /patch_pi.py

# Copy extension list and entrypoint
COPY pi-extensions.txt /pi-extensions.txt
COPY entrypoint.sh /entrypoint.sh

# Remove existing node user and create agent user (UID 1000)
RUN userdel -r node && useradd -m -u 1000 -s /bin/bash agent

# Fix line endings (CRLF -> LF) in case file was edited on Windows
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 19432
USER agent
WORKDIR /app

ENTRYPOINT ["/entrypoint.sh"]

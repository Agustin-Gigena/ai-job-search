# --------------------------------------------------------------
# Base image: Node 20 (Debian Bookworm) → GLIBC 2.36 (meets Bun's ≥2.32)
# --------------------------------------------------------------
FROM node:20-slim

# ----------------------
# System dependencies
# ----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 python3.11-venv python3.11-distutils \
        curl wget git zip unzip \
    && rm -rf /var/lib/apt/lists/*

# ----------------------
# Bun (installed for the node user, symlinked globally)
# ----------------------
ENV BUN_INSTALL=/usr/local/bun
RUN curl -fsSL https://bun.sh/install | bash && \
    ln -s ${BUN_INSTALL}/bin/bun /usr/local/bin/bun

# ----------------------
# n8n (global npm install)
# ----------------------
RUN npm install -g n8n

# ----------------------
# Ensure sudo is available and node user can use it without password
# ----------------------
RUN apt-get update && apt-get install -y --no-install-recommends sudo && \
    echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node && \
    chmod 0440 /etc/sudoers.d/node

# ----------------------
# Workspace setup
# ----------------------
WORKDIR /workspace
RUN chown -R node:node /workspace

# ----------------------
# Switch to non‑root user
# ----------------------
USER node

# ----------------------
# Optional: verify installations (can also be done in postCreate)
# ----------------------
RUN node --version && npm --version && python3 --version && bun --version && n8n --version
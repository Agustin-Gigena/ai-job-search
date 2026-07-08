# AI Job Search API - Dockerfile
# Multi-stage build for optimized production image

# ============================================
# Stage 1: Builder - Install all dependencies
# ============================================
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (for job portal CLI tools)
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL=/root/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# ============================================
# Stage 2: Runtime - Lean production image
# ============================================
FROM python:3.11-slim as runtime

WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/root/.bun/bin:$PATH

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    # LaTeX for CV compilation
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-xetex \
    texlive-luatex \
    lmodern \
    moderncv \
    # PDF utilities for ATS checking
    poppler-utils \
    # Git for version control
    git \
    # Curl for health checks
    curl \
    # Clean up
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && tlmgr install \
        moderncv fontawesome5 fontawesome6 academicons import luatexbase pgf \
        titlesec textpos xltxtra xunicode cite realscripts \
    || true  # Some packages might already be installed

# Install Bun (for job portal CLI tools)
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL=/root/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Copy Python packages from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application code
COPY --chown=appuser:appuser . .

# Create necessary directories
RUN mkdir -p /app/data/structures /app/output /app/logs && \
    chmod -R 755 /app/data /app/output /app/logs

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Entry point
ENTRYPOINT ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

# Default command (can be overridden in docker-compose)
CMD []
#!/bin/bash
set -e

echo "🔧 Setting up AI Job Search development environment..."

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Install Bun (if not already installed)
if ! command -v bun &> /dev/null; then
    echo "📦 Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Install job portal CLI dependencies
echo "📦 Installing job portal CLI tools..."
cd tools/job-portal-cli
for dir in */; do
    if [ -d "$dir" ]; then
        echo "  Installing $dir..."
        cd "$dir" && bun install && cd ..
    fi
done
cd ../..

# Create necessary directories
mkdir -p data/structures
mkdir -p output
mkdir -p logs

# Initialize git submodules if any
git submodule update --init --recursive 2>/dev/null || true

echo "✅ Development environment ready!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and configure your settings"
echo "2. Run 'docker-compose up' to start n8n and the API"
echo "3. Access n8n at http://localhost:5678"
echo "4. Access the API at http://localhost:8000/docs"
#!/bin/bash
set -e

echo "🔧 Verifying AI Job Search dev environment..."

echo "Node.js: $(node --version)"
echo "npm:     $(npm --version)"
echo "Python:  $(python3 --version)"
echo "Bun:     $(bun --version)"
echo "n8n:     $(n8n --version)"
echo ""
sudo chown -R node:node /workspaces
echo "✅ All tools are ready."
echo "📁 Workspace: /workspace (owned by $(whoami))"
echo "🌐 n8n UI:    http://localhost:5678"
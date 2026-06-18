#!/bin/bash
set -e

# Initialize devcontainer (runs before post-create)
echo "Initializing secure Copilot development environment..."

# Ensure necessary host-side directories exist
mkdir -p ~/.ssh ~/.config ~/.azure

# Set proper permissions on SSH
if [ -d ~/.ssh ]; then
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/* 2>/dev/null || true
fi

echo "Devcontainer initialization complete"

#!/bin/bash
set -e

echo "Setting up secure Copilot development environment..."

# Install global npm tools
echo "Installing global npm tools..."
npm install -g \
    @github/copilot

# Clean npm cache
npm cache clean --force

# Initialize pre-commit hooks
echo "Initializing pre-commit hooks..."
pre-commit install
pre-commit install --hook-type pre-push

# Set up git credentials
echo "Configuring git security..."
git config --global core.safecrlf false
git config --local core.safecrlf false

# Seed Copilot CLI's personal settings.json - approve per session, not
# globally. ~/.copilot is a persisted named volume, so this only runs once
# per volume lifetime; never overwrite a dev's existing approvals.
echo "Seeding Copilot CLI settings..."
mkdir -p "$HOME/.copilot"
if [ ! -f "$HOME/.copilot/settings.json" ]; then
    cat > "$HOME/.copilot/settings.json" << 'EOF'
{
  "trusted_folders": [],
  "denied_urls": ["*"]
}
EOF
    echo "Created ~/.copilot/settings.json (empty trusted_folders, denied_urls)"
else
    echo "  ~/.copilot/settings.json already exists, leaving as-is"
fi

# Set locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Install local .NET tools from .config/dotnet-tools.json
echo "Installing .NET global tools..."
if [ -f .config/dotnet-tools.json ]; then
    dotnet tool restore
else
    echo "  Skipping dotnet tool restore: no .config/dotnet-tools.json found"
fi

# Initialize .NET NuGet credential provider
echo "Setting up NuGet credentials provider..."
export NUGET_PLUGIN_PATHS=/opt/nuget-plugins

# Create .env stub if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << 'EOF'
# Development environment variables
ASPNETCORE_ENVIRONMENT=Development
DOTNET_CLI_TELEMETRY_OPTOUT=1
NODE_ENV=development
EOF
    echo "Created .env template (update as needed)"
fi

# Verify tools are installed
echo "Verifying installed tools..."
echo "  .NET SDK: $(dotnet --version)"
echo "  Node: $(node --version)"
echo "  npm: $(npm --version)"
echo "  pre-commit: $(pre-commit --version)"
echo "  detect-secrets: $(python3 -m detect_secrets --version 2>/dev/null || echo 'installed')"
echo "  gitleaks: $(gitleaks version | head -1 || echo 'installed')"
echo "  checkov: $(python3 -m checkov --version 2>/dev/null || echo 'installed')"

echo "Setup complete. Your secure Copilot development environment is ready."

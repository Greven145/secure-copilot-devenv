# mcr.microsoft.com/devcontainers/dotnet:10.0-noble
FROM mcr.microsoft.com/devcontainers/dotnet@sha256:da953a31996cf89df8c506a5d7ed9374f4285af6f728b55d772cd2d8e205cdef

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN if ! command -v node >/dev/null 2>&1 && command -v nodejs >/dev/null 2>&1; then \
    ln -s "$(command -v nodejs)" /usr/local/bin/node; \
    fi

# Block npm/pnpm/yarn lifecycle scripts globally - postinstall hooks are a
# supply-chain execution vector, not an edge case. Allowlist exceptions with
# `npm approve-scripts`, don't re-enable this globally.
RUN echo "ignore-scripts=true" >> /etc/npmrc

# Install security and development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs \
    gnupg \
    jq \
    ripgrep \
    pipx \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install pipx-backed tools globally
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin

RUN python3 -m pipx install --system-site-packages pre-commit==3.7.0 && \
    python3 -m pipx install --system-site-packages detect-secrets==1.5.0 && \
    python3 -m pipx install --system-site-packages checkov==3.2.78 && \
    pipx ensurepath

# Install gitleaks (secret scanning)
RUN curl -sL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_x64.tar.gz | \
    tar -xz -C /tmp && \
    mv /tmp/gitleaks /usr/local/bin/

# Install GitHub Actions linters
RUN python3 -m pipx install --system-site-packages zizmor==1.24.1 && \
    npm install -g actionlint@2.0.6

# Install Azure Artifacts Credential Provider
RUN mkdir -p /opt/nuget-plugins && \
    curl -sL https://github.com/microsoft/artifacts-credprovider/releases/download/v2.0.3/Microsoft.linux-x64.NuGet.CredentialProvider.tar.gz | \
    tar -xz -C /opt/nuget-plugins

# Install CodeQL CLI
RUN mkdir -p /opt/codeql && \
    curl -sL https://github.com/github/codeql-cli-binaries/releases/download/v2.21.4/codeql-linux64.zip -o /tmp/codeql.zip && \
    unzip -q /tmp/codeql.zip -d /opt/codeql && \
    ln -s /opt/codeql/codeql/codeql /usr/local/bin/codeql && \
    rm /tmp/codeql.zip

# Install Aspire CLI
RUN dotnet tool install --global --version 13.4.4 Aspire.Cli

# Create ReportGenerator for Cobertura → SonarQube XML conversion
RUN dotnet tool install --global dotnet-reportgenerator-globaltool --version 5.5.1

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages focal main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends gh=2.95.0 && \
    rm -rf /var/lib/apt/lists/*

# Prepare a writable npm prefix for the vscode user.
RUN id -u vscode >/dev/null 2>&1 || useradd -m -s /bin/bash vscode

ENV NPM_CONFIG_PREFIX=/home/vscode/.npm-global
ENV PATH=/home/vscode/.npm-global/bin:${PATH}

# Switch back to vscode user
USER vscode

RUN mkdir -p /home/vscode/.ssh \
    /home/vscode/.azure \
    /home/vscode/.config/gh \
    /home/vscode/.npm \
    /home/vscode/.nuget \
    /home/vscode/.npm-cache \
    /home/vscode/.nuget-cache \
    /home/vscode/.memory \
    /home/vscode/.npm-global \
    /home/vscode/.cache/pre-commit \
    /home/vscode/.copilot/ \
    /home/vscode/.vscode-server/data/User && \
    touch /home/vscode/.bash_history


# Global npm tools
RUN npm install -g \
    @marp-team/marp-cli@4.4.0 \
    && npm cache clean --force

# Hard-deny destructive/network shell calls by default. This wraps the real
# `copilot` binary so the flags apply every session without anyone having to
# remember to type them - never alias this to --yolo/--allow-all instead.
RUN printf '%s\n' \
    '' \
    'copilot() {' \
    '  command copilot \' \
    '    --deny-tool="shell(rm)" \' \
    '    --deny-tool="shell(curl)" \' \
    '    --deny-tool="shell(env)" \' \
    '    --allow-tool="shell(git status)" \' \
    '    --disallow-temp-dir \' \
    '    "$@"' \
    '}' \
    >> /home/vscode/.bashrc

WORKDIR /workspaces/secure-copilot-devenv

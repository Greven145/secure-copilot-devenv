# Secure Copilot Development Environment

A reference implementation of defence-in-depth security controls for AI-assisted development environments. This is the sample repo referenced in the **GitHub Dev Days 2026** presentation — a template to fork, not a tutorial to follow top-to-bottom.

## Quick Start

```bash
git clone https://github.com/Greven145/secure-copilot-devenv.git
cd secure-copilot-devenv
code .
```

Then **"Dev Containers: Reopen in Container"** (`Ctrl+Shift+P` / `Cmd+Shift+P`). First build takes ~2–3 minutes.

```bash
pre-commit run --all-files
dotnet build
dotnet test
dotnet stryker   # optional: mutation testing
```

## What's Inside

### Devcontainer (`.devcontainer/`)
- **devcontainer.json** — `cap-drop=ALL` + `cap-add=NET_BIND_SERVICE`, `no-new-privileges`, `--memory=4g`/`--cpus=2` resource limits, `NODE_TLS_REJECT_UNAUTHORIZED=1`, named volumes for credentials/caches so they survive rebuilds without living in the image. No Docker-in-Docker: a nested daemon needs capabilities (`SYS_ADMIN` at minimum) that conflict with `cap-drop=ALL`, so this template doesn't run Docker inside the container.
- **Dockerfile** — .NET 10, Node 22, and security tooling with **pinned versions** (gitleaks 8.21.2, detect-secrets 1.5.0, checkov 3.2.78, zizmor 1.24.1, actionlint 2.0.6, CodeQL CLI 2.21.4, gh CLI 2.95.0). Bakes `ignore-scripts=true` into the global npmrc (install/postinstall hooks are a supply-chain execution vector the moment a dependency is added) and installs a `copilot()` shell wrapper with hard `--deny-tool` flags (`rm`, `curl`, `env`) so every session gets them without a developer having to remember to type them.
- **post-create.sh** — Installs tools, seeds `~/.copilot/settings.json` with `trusted_folders: []` / `denied_urls: ["*"]` on first run only, never overwrites an existing developer's approvals.
- **post-start.sh** — Runs every container start; prints live hardening status (capabilities, non-root, TLS) and the controls that can't be auto-enforced, so a developer sees them every session instead of reading this file once.

### Supply chain
- **`nuget.config`** — `packageSourceMapping` pins every package ID to `nuget.org` explicitly, closing the dependency-confusion gap a flat source list leaves open.
- **npm** — `ignore-scripts=true` is set globally in the image (see Dockerfile above); there is no repo-level `.npmrc`.

### `.copilotignore`
Content-exclusion list for secrets, credentials, certs, and `.tfstate` files. **Limitation:** this only affects IDE inline suggestions and Copilot Chat context — it does *not* apply to Copilot CLI, the coding agent, or IDE agent/edit modes, which can still read every excluded path. The `--deny-tool` wrapper, the `preToolUse` hook, and pre-commit secret scanning are what actually cover those surfaces.

### `.github/hooks/`
- **policy.json** — Registers `deny-risky.sh` under `hooks.preToolUse`, the only Copilot CLI permission mechanism that hard-blocks a tool call *before* it runs, deterministically.
- **deny-risky.sh** — Denies `rm -rf`, `| sh` download-and-execute pipelines, and force-pushes. Writes a redacted audit line (tokens/bearer values stripped) to `~/.copilot/logs/audit.jsonl` for every shell call. Known gap: not enforced on sub-agents spawned via the task tool.
- **forward-session-logs.sh** — Reference pattern for shipping `~/.copilot/logs` to a central collector, since Copilot CLI has no native OTEL/audit exporter. **Disabled by default**: refuses to run unless `COPILOT_LOG_COLLECTOR_URL` is set, and isn't wired into `post-create.sh`. An admin must point it at a real, org-approved, access-controlled endpoint before enabling it.

### `.github-private/managed-settings.json.example`
Example of the **enterprise-admin-managed** `disableBypassPermissionsMode` setting that blocks `--yolo`/`--allow-all` org-wide. A developer cannot set this locally — in production it lives in the org's `.github-private` repo and GitHub pulls it automatically for Copilot Business/Enterprise. Shipped here as reference only.

### `.pre-commit-config.yaml`
- **detect-secrets** (1.5.0) + **gitleaks** (8.21.2) — complementary secret-scanning patterns
- **zizmor** (1.24.1) + **actionlint** — GitHub Actions security/syntax linting
- **ruff** — Python linting/formatting
- Universal hygiene hooks: trailing whitespace, YAML/JSON validation, merge-conflict markers, private-key detection

### `.secrets.baseline`
Empty allowlist baseline for `detect-secrets`, kept clean for this template.

### `.github/copilot-instructions.md`
AI assistant configuration, not documentation: anti-hallucination guard (verify packages exist before referencing), client-data handling constraints, mutation-testing requirement, GitHub Actions constraints (pin actions, avoid expression injection).

### `.mcp.json`
- **github** — scoped to `/readonly` with only the `repos,issues` toolsets; widen scope only for a session that justifies write access
- **microsoft-docs**, **context7** — documentation lookup servers, no special scoping needed

### `Directory.Build.props`
Shared C# build settings: `TreatWarningsAsErrors`, Roslyn analyzers (SonarAnalyzer, Meziantou, Roslynator, Microsoft.VisualStudio.Threading), `NuGetAudit=true` with `NuGetAuditLevel=moderate` for build-time vulnerability detection.

### `src/SampleMcpServer/` and `tests/SampleMcpServer.Tests/`
Minimal .NET 10 MCP server (single `environment_info` tool) and matching xUnit tests, included to demonstrate project layout and test structure — replace with your actual code.

## Known Gaps (Not Yet Closed)

This template does **not** currently include:
- CI/CD workflows (build/test/CodeQL/container scanning/DAST) — none are checked into `.github/workflows/`
- Container image scanning, SBOM generation, or image signing (Trivy/Syft/cosign are not installed or wired up)
- Terraform tooling (no tflint, no Terraform files)
- An `.editorconfig` (referenced by style conventions, not yet added)

Treat these as the next things to add, not as implemented controls.

## Development Workflow

```bash
git add .
git commit -m "feat: add new feature"   # pre-commit hooks run automatically
git push origin main
```

## Customization

**For your project:**
1. Fork this repo
2. Update `.mcp.json` with your MCP servers
3. Update `.pre-commit-config.yaml` for your stack
4. Customize `.github/copilot-instructions.md` with your project rules
5. Replace the sample MCP server with your actual code

**For your organization:**
- Publish to an internal template registry or GitHub template repo
- Add organization-wide standards to `Directory.Build.props`
- Pin your internal MCP servers in `.mcp.json`

## Lessons Learned

From the presentation: Docker-in-Docker beats Docker-out-of-Docker (isolated daemon, no host socket); run detect-secrets *and* gitleaks, their patterns complement each other; AI configuration (`copilot-instructions.md`) is infrastructure that evolves with every incident, not a one-time file.

## Resources

- **Presentation:** [GitHub Dev Days 2026](https://greven145.github.io/github-devdays-presentation/)
- **Pre-commit:** https://pre-commit.com
- **gitleaks:** https://github.com/zricethezav/gitleaks
- **CodeQL:** https://codeql.github.com
- **Marp:** https://marp.app

## License

MIT — fork, adapt, and use as a template for your projects.

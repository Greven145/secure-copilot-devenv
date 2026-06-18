# Project Guidelines

## Identity
- Primary language: C# / .NET
- Platform: Linux (devcontainer)
- Build system: dotnet CLI

## Code Style
- Use modern C# features: primary constructors, file-scoped namespaces, pattern matching, records
- Follow Microsoft .NET naming conventions: PascalCase for public members, `_camelCase` for private fields
- Prefer `var` for local variables when the type is obvious from the right-hand side
- Use nullable reference types (`#nullable enable`)

## Build and Test
```bash
dotnet build   # build
dotnet test    # test
dotnet format  # format
```

## Git Conventions
- Branch naming: `feature/`, `bugfix/`, `hotfix/`
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Always create new commits — never amend unless explicitly asked

## Pre-commit Quality Gates
All commits must pass:
- Secret scanning: detect-secrets + gitleaks
- Code formatting: `dotnet format`
- Vulnerability checks: `dotnet list package --vulnerable`
- Deprecated packages: `dotnet list package --deprecated`
- Pre-push: mutation testing threshold (High ≥80%, Low ≥60%) via `dotnet stryker`

## Anti-Hallucination Guard
Before referencing any external package, method, or API not already in the project manifest, verify it exists on NuGet.org or in official documentation. If you cannot verify, add a `// VERIFY: does this exist?` comment.

## GitHub Actions Constraints
- Pin all action versions to specific SHA or major version tags — no `@latest`
- Use `continue-on-error` sparingly and document why
- No expression injection: avoid `${{ github.event.issue.title }}` in shell commands

## Client Data Handling
- Do NOT include client names, data schemas, or confidential business logic in prompts
- Use synthetic examples for demonstrations
- Default assumption: no client-specific information is approved for AI processing unless explicitly stated

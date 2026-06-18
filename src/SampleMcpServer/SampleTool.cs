using ModelContextProtocol.SDK.Types;

namespace SampleMcpServer;

/// <summary>
/// Simple sample MCP server demonstrating security best practices.
/// This server provides a single tool for demonstration purposes.
/// </summary>
public class SampleTool
{
    /// <summary>
    /// Gets information about the secure environment.
    /// </summary>
    public static Tool GetEnvironmentInfoTool() => new()
    {
        Name = "environment_info",
        Description = "Get information about the secure Copilot development environment",
        InputSchema = new()
        {
            Type = "object",
            Properties = new()
            {
                {
                    "category",
                    new()
                    {
                        Type = "string",
                        Description = "Category: 'security', 'tools', or 'all'",
                        Enum = ["security", "tools", "all"]
                    }
                }
            },
            Required = ["category"]
        }
    };

    /// <summary>
    /// Executes the environment_info tool.
    /// </summary>
    public static object ExecuteEnvironmentInfo(string category)
    {
        return category switch
        {
            "security" => new
            {
                message = "Security controls enabled",
                controls = new[]
                {
                    "pre-commit hooks: detect-secrets + gitleaks",
                    "Roslyn build-time analyzers",
                    "CodeQL SAST scanning",
                    "Trivy container scanning",
                    "Docker-in-Docker (no host socket)",
                    "Capability restrictions (cap-drop=ALL)"
                }
            },
            "tools" => new
            {
                message = "Development tools available",
                tools = new[]
                {
                    ".NET 10 SDK",
                    "Node.js 22",
                    "CodeQL CLI v2.21.4",
                    "Aspire CLI v13.4.4",
                    "GitHub CLI v2.95.0"
                }
            },
            "all" => new
            {
                message = "Secure Copilot Development Environment",
                version = "1.0.0",
                documentation = "https://github.com/Greven145/secure-copilot-devenv"
            },
            _ => throw new ArgumentException($"Unknown category: {category}")
        };
    }
}

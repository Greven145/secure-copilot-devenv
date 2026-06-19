using ModelContextProtocol.Server;
using System.ComponentModel;

namespace AspNetCoreMcpServer.Tools;

/// <summary>
/// A simple tool that echoes messages back to the client.
/// </summary>
[McpServerToolType]
public sealed class EchoTool
{
    /// <summary>
    /// Echoes the input message back to the client.
    /// </summary>
    /// <param name="message"></param>
    /// <returns></returns>
    [McpServerTool, Description("Echoes the input back to the client.")]
    public static string Echo(string message)
    {
        return "hello " + message;
    }
}

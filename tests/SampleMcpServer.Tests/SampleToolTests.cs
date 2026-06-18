using Xunit;

namespace SampleMcpServer.Tests;

public class SampleToolTests
{
    [Fact]
    public void GetEnvironmentInfoTool_ReturnsValidTool()
    {
        // Arrange & Act
        var tool = SampleTool.GetEnvironmentInfoTool();

        // Assert
        Assert.NotNull(tool);
        Assert.Equal("environment_info", tool.Name);
        Assert.NotEmpty(tool.Description);
        Assert.NotNull(tool.InputSchema);
    }

    [Theory]
    [InlineData("security")]
    [InlineData("tools")]
    [InlineData("all")]
    public void ExecuteEnvironmentInfo_WithValidCategory_ReturnsObject(string category)
    {
        // Act
        var result = SampleTool.ExecuteEnvironmentInfo(category);

        // Assert
        Assert.NotNull(result);
    }

    [Fact]
    public void ExecuteEnvironmentInfo_WithInvalidCategory_ThrowsArgumentException()
    {
        // Act & Assert
        _ = Assert.Throws<ArgumentException>(() => SampleTool.ExecuteEnvironmentInfo("invalid"));
    }

    [Fact]
    public void ExecuteEnvironmentInfo_Security_ContainsExpectedControls()
    {
        // Act
        var result = SampleTool.ExecuteEnvironmentInfo("security");

        // Assert
        Assert.NotNull(result);
        var resultString = result.ToString();
        Assert.Contains("gitleaks", resultString);
        Assert.Contains("Roslyn", resultString);
    }
}

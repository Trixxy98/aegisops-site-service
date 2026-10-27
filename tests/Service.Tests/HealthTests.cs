using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;

namespace Service.Tests;

public sealed class HealthTests : IClassFixture<WebApplicationFactory<Program>> {
    private readonly WebApplicationFactory<Program> _factory;

    public HealthTests(WebApplicationFactory<Program> factory) {
        _factory = factory;
    }

    [Fact]
    public async Task Health_and_version_respond() {
        var client = _factory.CreateClient();
        var health = await client.GetAsync("/health");
        var version = await client.GetAsync("/version");
        Assert.Equal(HttpStatusCode.OK, health.StatusCode);
        Assert.Equal(HttpStatusCode.OK, version.StatusCode);
    }

    [Theory]
    [InlineData("Staging", true, HttpStatusCode.ServiceUnavailable)]
    [InlineData("Staging", false, HttpStatusCode.OK)]
    [InlineData("Production", true, HttpStatusCode.OK)]
    public async Task Health_failure_fixture_is_opt_in_and_staging_only(string environment, bool enabled, HttpStatusCode expected) {
        using var factory = _factory.WithWebHostBuilder(builder => {
            builder.UseEnvironment(environment);
            builder.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?> {
                ["AegisOpsFixture:FailHealth"] = enabled.ToString(),
            }));
        });
        using var client = factory.CreateClient();
        Assert.Equal(expected, (await client.GetAsync("/health")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/version")).StatusCode);
    }
}

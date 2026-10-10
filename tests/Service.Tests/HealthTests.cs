using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

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
}

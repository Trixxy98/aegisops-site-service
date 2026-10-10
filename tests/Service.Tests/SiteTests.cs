using Microsoft.AspNetCore.Mvc.Testing;

namespace Service.Tests;

public sealed class SiteTests : IClassFixture<WebApplicationFactory<Program>> {
    private readonly WebApplicationFactory<Program> _factory;

    public SiteTests(WebApplicationFactory<Program> factory) {
        _factory = factory;
    }

    [Fact]
    public async Task Seeded_site_is_listed() {
        var client = _factory.CreateClient();
        var body = await client.GetStringAsync("/sites");
        Assert.Contains("KUL-01", body, StringComparison.Ordinal);
    }
}

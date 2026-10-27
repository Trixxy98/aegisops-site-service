using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var info = app.Configuration.GetSection("Service").Get<ServiceInfo>() ?? new ServiceInfo();
var sites = new ConcurrentDictionary<string, Site>(StringComparer.OrdinalIgnoreCase);
var devices = new ConcurrentDictionary<string, List<Device>>(StringComparer.OrdinalIgnoreCase);
sites["KUL-01"] = new Site("KUL-01", "Kuala Lumpur Core", "Kuala Lumpur", "Central");
devices["KUL-01"] = [new Device("kul-core-r1", "router", "Cisco", "10.0.0.1")];

app.MapGet("/", () => Results.Ok(new { service = info.Name }));
// Only the opt-in Staging rollback fixture may make the service unhealthy.
app.MapGet("/health", () => app.Environment.IsEnvironment("Staging") && app.Configuration.GetValue<bool>("AegisOpsFixture:FailHealth")
    ? Results.StatusCode(StatusCodes.Status503ServiceUnavailable)
    : Results.Ok(new { status = "Healthy" }));
app.MapGet("/version", () => Results.Ok(new {
    service = info.Name,
    version = info.Version,
    commitSha = info.CommitSha,
    buildTime = info.BuildTime,
    environment = app.Environment.EnvironmentName,
}));
app.MapGet("/sites", () => sites.Values.OrderBy(site => site.Code));
app.MapGet("/sites/{code}", (string code) => sites.TryGetValue(code, out var site) ? Results.Ok(site) : Results.NotFound());
app.MapPost("/sites", (Site site) => {
    if (string.IsNullOrWhiteSpace(site.Code) || string.IsNullOrWhiteSpace(site.Name)) {
        return Results.Problem(title: "Code and name are required.", statusCode: StatusCodes.Status400BadRequest);
    }

    if (!sites.TryAdd(site.Code.Trim(), site with { Code = site.Code.Trim() })) {
        return Results.Problem(title: "Site already exists.", statusCode: StatusCodes.Status409Conflict);
    }

    return Results.Created($"/sites/{site.Code.Trim()}", sites[site.Code.Trim()]);
});
app.MapGet("/sites/{code}/devices", (string code) => sites.ContainsKey(code) ? Results.Ok(devices.GetValueOrDefault(code) ?? []) : Results.NotFound());
app.MapPost("/sites/{code}/devices", (string code, Device device) => {
    if (!sites.ContainsKey(code)) {
        return Results.NotFound();
    }

    if (string.IsNullOrWhiteSpace(device.Hostname) || string.IsNullOrWhiteSpace(device.Role)) {
        return Results.Problem(title: "Hostname and role are required.", statusCode: StatusCodes.Status400BadRequest);
    }

    var list = devices.GetOrAdd(code, _ => []);
    lock (list) {
        list.Add(device);
    }

    return Results.Created($"/sites/{code}/devices", device);
});

app.Run();

public sealed record Site(string Code, string Name, string Address, string Region);
public sealed record Device(string Hostname, string Role, string Vendor, string ManagementIp);

public sealed class ServiceInfo {
    public string Name { get; set; } = "site-service";
    public string Version { get; set; } = "v0.0.0-dev";
    public string CommitSha { get; set; } = "local";
    public string BuildTime { get; set; } = "unknown";
}

public partial class Program;

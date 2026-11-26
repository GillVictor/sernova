using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace ServNova.Api.Tests;

/// <summary>The OpenAPI document is served in Development, or in production only when switched on.</summary>
public class OpenApiTests
{
    private sealed class EnvFactory(string environment, string? enabled = null) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment(environment);
            if (enabled is not null) builder.UseSetting("OpenApi:Enabled", enabled);
        }
    }

    [Fact]
    public async Task In_development_the_document_lists_the_health_route()
    {
        using var factory = new EnvFactory("Development");
        var response = await factory.CreateClient().GetAsync("/openapi/v1.json");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Contains("/api/v1/health", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task In_production_the_document_is_not_served_by_default()
    {
        using var factory = new EnvFactory("Production");
        var response = await factory.CreateClient().GetAsync("/openapi/v1.json");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task In_production_the_document_is_served_when_explicitly_enabled()
    {
        using var factory = new EnvFactory("Production", enabled: "true");
        var response = await factory.CreateClient().GetAsync("/openapi/v1.json");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}

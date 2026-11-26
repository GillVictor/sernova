using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using ServNova.Api.RateLimiting;

namespace ServNova.Api.Tests;

/// <summary>Convention "Limitation de débit": 429 RATE_LIMITED with Retry-After, in problem+json.</summary>
public class RateLimitingTests
{
    /// <summary>A fresh server per test, so the counters never leak from one test to another.</summary>
    private sealed class LimitedFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder) =>
            builder.ConfigureServices(services =>
            {
                services.AddControllers().AddApplicationPart(typeof(FailureController).Assembly);
                services.PostConfigure<RateLimitSettings>(s =>
                {
                    s.Global = new LimitSettings { PermitLimit = 2, WindowSeconds = 60 };
                    s.Strict = new LimitSettings { PermitLimit = 1, WindowSeconds = 60 };
                });
            });
    }

    [Fact]
    public async Task Above_the_global_limit_the_answer_is_429_problem_json_with_Retry_After()
    {
        using var factory = new LimitedFactory();
        var client = factory.CreateClient();

        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/_test/ping")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/_test/ping")).StatusCode);
        var limited = await client.GetAsync("/api/v1/_test/ping");

        Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
        Assert.Equal("application/problem+json", limited.Content.Headers.ContentType?.MediaType);
        Assert.True(limited.Headers.TryGetValues("Retry-After", out var values));
        Assert.True(int.TryParse(values!.Single(), out var seconds) && seconds is >= 1 and <= 60);
        var body = await limited.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(429, body.GetProperty("status").GetInt32());
        Assert.Equal("RATE_LIMITED", body.GetProperty("code").GetString());
        Assert.False(string.IsNullOrWhiteSpace(body.GetProperty("traceId").GetString()));
    }

    [Fact]
    public async Task Health_is_never_rate_limited_so_monitoring_keeps_working()
    {
        using var factory = new LimitedFactory();
        var client = factory.CreateClient();

        for (var i = 0; i < 10; i++)
            Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/health")).StatusCode);
    }

    [Fact]
    public async Task The_strict_policy_limits_a_sensitive_route_below_the_global_limit()
    {
        using var factory = new LimitedFactory();
        var client = factory.CreateClient();

        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/api/v1/_test/strict")).StatusCode);
        var limited = await client.GetAsync("/api/v1/_test/strict");

        Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
        var body = await limited.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("RATE_LIMITED", body.GetProperty("code").GetString());
        Assert.True(limited.Headers.Contains("Retry-After"));
    }
}

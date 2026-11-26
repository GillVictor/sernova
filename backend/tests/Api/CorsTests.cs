using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using ServNova.Api.Cors;

namespace ServNova.Api.Tests;

/// <summary>CORS: no origin is allowed unless it is listed in the configuration (fail closed).</summary>
public class CorsTests
{
    private const string AdminOrigin = "https://admin.servnova.example";

    private sealed class CorsFactory(params string[] origins) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder) =>
            builder.ConfigureServices(services =>
                services.PostConfigure<CorsSettings>(s => s.AllowedOrigins = origins));
    }

    private static HttpRequestMessage Preflight(string origin, string method = "POST", string headers = "authorization,content-type,idempotency-key,if-match")
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/v1/health");
        request.Headers.Add("Origin", origin);
        request.Headers.Add("Access-Control-Request-Method", method);
        request.Headers.Add("Access-Control-Request-Headers", headers);
        return request;
    }

    [Fact]
    public async Task A_listed_origin_gets_its_preflight_accepted_with_the_contract_headers()
    {
        using var factory = new CorsFactory(AdminOrigin);
        var response = await factory.CreateClient().SendAsync(Preflight(AdminOrigin));

        Assert.True(response.StatusCode is HttpStatusCode.NoContent or HttpStatusCode.OK);
        Assert.Equal(AdminOrigin, response.Headers.GetValues("Access-Control-Allow-Origin").Single());
        var allowed = string.Join(",", response.Headers.GetValues("Access-Control-Allow-Headers")).ToLowerInvariant();
        foreach (var header in new[] { "authorization", "content-type", "idempotency-key", "if-match" })
            Assert.Contains(header, allowed);
        Assert.Contains("PATCH", string.Join(",", response.Headers.GetValues("Access-Control-Allow-Methods")));
    }

    [Fact]
    public async Task An_unlisted_origin_gets_no_CORS_header()
    {
        using var factory = new CorsFactory(AdminOrigin);
        var response = await factory.CreateClient().SendAsync(Preflight("https://evil.example"));

        Assert.False(response.Headers.Contains("Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task Without_configuration_no_origin_is_allowed()
    {
        using var factory = new CorsFactory();
        var response = await factory.CreateClient().SendAsync(Preflight(AdminOrigin));

        Assert.False(response.Headers.Contains("Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task A_simple_request_from_a_listed_origin_exposes_ETag_and_Retry_After()
    {
        using var factory = new CorsFactory(AdminOrigin);
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/health");
        request.Headers.Add("Origin", AdminOrigin);
        var response = await factory.CreateClient().SendAsync(request);

        Assert.Equal(AdminOrigin, response.Headers.GetValues("Access-Control-Allow-Origin").Single());
        var exposed = string.Join(",", response.Headers.GetValues("Access-Control-Expose-Headers"));
        Assert.Contains("ETag", exposed);
        Assert.Contains("Retry-After", exposed);
    }

    [Theory]
    [InlineData("*")]
    [InlineData("admin.servnova.example")]
    [InlineData("http://admin.servnova.example")]
    [InlineData("https://admin.servnova.example/path")]
    public void An_invalid_origin_in_the_configuration_stops_the_startup(string origin)
    {
        using var factory = new CorsFactory(origin);

        Assert.ThrowsAny<Exception>(() => factory.CreateClient());
    }

    [Fact]
    public async Task Plain_http_is_accepted_for_localhost_only_to_ease_local_development()
    {
        using var factory = new CorsFactory("http://localhost:3000");
        var response = await factory.CreateClient().SendAsync(Preflight("http://localhost:3000"));

        Assert.Equal("http://localhost:3000", response.Headers.GetValues("Access-Control-Allow-Origin").Single());
    }
}

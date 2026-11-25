using System.Net;
using System.Net.Http.Json;

namespace ServNova.Api.Tests;

/// <summary>EP-113: GET /api/v1/health, public, 200 {status}.</summary>
public class HealthEndpointTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Health_is_public_and_answers_200_with_a_status()
    {
        var response = await _client.GetAsync("/api/v1/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("ok", body["status"]);
    }

    [Fact]
    public async Task Health_does_not_exist_outside_the_versioned_prefix()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}

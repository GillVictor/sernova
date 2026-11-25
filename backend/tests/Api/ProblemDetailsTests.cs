using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace ServNova.Api.Tests;

/// <summary>Convention "Erreurs": problem+json (RFC 9457) with a stable <c>code</c> and a <c>traceId</c>.</summary>
public class ProblemDetailsTests(ApiFactory factory) : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Unknown_route_answers_404_problem_json_with_NOT_FOUND()
    {
        var response = await _client.GetAsync("/api/v1/does-not-exist");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(404, body.GetProperty("status").GetInt32());
        Assert.Equal("NOT_FOUND", body.GetProperty("code").GetString());
        Assert.Equal("Ressource introuvable", body.GetProperty("title").GetString());
        Assert.False(string.IsNullOrWhiteSpace(body.GetProperty("traceId").GetString()));
    }

    [Fact]
    public async Task Unhandled_exception_answers_500_problem_json_without_leaking_details()
    {
        var response = await _client.GetAsync("/api/v1/_test/boom");

        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
        var raw = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain(FailureController.SecretMessage, raw);
        Assert.DoesNotContain("InvalidOperationException", raw);
        Assert.DoesNotContain("   at ", raw); // no stack trace
        var body = JsonDocument.Parse(raw).RootElement;
        Assert.Equal(500, body.GetProperty("status").GetInt32());
        Assert.Equal("INTERNAL_ERROR", body.GetProperty("code").GetString());
        Assert.False(string.IsNullOrWhiteSpace(body.GetProperty("traceId").GetString()));
    }

    [Fact]
    public async Task Two_requests_get_two_different_traceIds()
    {
        var first = await (await _client.GetAsync("/api/v1/nope-1")).Content.ReadFromJsonAsync<JsonElement>();
        var second = await (await _client.GetAsync("/api/v1/nope-2")).Content.ReadFromJsonAsync<JsonElement>();

        Assert.NotEqual(first.GetProperty("traceId").GetString(), second.GetProperty("traceId").GetString());
    }
}

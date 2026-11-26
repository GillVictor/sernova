using System.Collections.Concurrent;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Serilog.Core;
using Serilog.Events;

namespace ServNova.Api.Tests;

/// <summary>AGENTS.md: structured logs whose correlation id is the <c>traceId</c> of the answer.</summary>
public class LoggingTests
{
    private sealed class CollectingSink : ILogEventSink
    {
        public ConcurrentQueue<LogEvent> Events { get; } = new();
        public void Emit(LogEvent logEvent) => Events.Enqueue(logEvent);
    }

    private sealed class LoggingFactory(CollectingSink sink) : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder) =>
            builder.ConfigureServices(services =>
            {
                services.AddControllers().AddApplicationPart(typeof(FailureController).Assembly);
                services.AddSingleton<ILogEventSink>(sink); // picked up by ReadFrom.Services(...)
            });
    }

    private static string? Text(LogEvent e, string property) =>
        e.Properties.TryGetValue(property, out var value) && value is ScalarValue { Value: string s } ? s : null;

    [Fact]
    public async Task A_request_is_logged_with_the_traceId_returned_in_the_answer()
    {
        var sink = new CollectingSink();
        using var factory = new LoggingFactory(sink);

        var response = await factory.CreateClient().GetAsync("/api/v1/does-not-exist");
        var traceId = (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("traceId").GetString();

        var requestLine = sink.Events.Single(e => Text(e, "RequestPath") == "/api/v1/does-not-exist");
        Assert.Equal(traceId, Text(requestLine, "TraceId"));
    }

    [Fact]
    public async Task An_unhandled_exception_is_logged_with_its_detail_and_the_same_traceId_but_not_returned()
    {
        var sink = new CollectingSink();
        using var factory = new LoggingFactory(sink);

        var response = await factory.CreateClient().GetAsync("/api/v1/_test/boom");
        var body = await response.Content.ReadAsStringAsync();
        var traceId = JsonDocument.Parse(body).RootElement.GetProperty("traceId").GetString();

        Assert.DoesNotContain(FailureController.SecretMessage, body);
        var error = sink.Events.First(e => e.Exception?.Message == FailureController.SecretMessage);
        Assert.Equal(LogEventLevel.Error, error.Level);
        Assert.Equal(traceId, Text(error, "TraceId"));
    }

    [Fact]
    public async Task Health_checks_do_not_fill_the_logs()
    {
        var sink = new CollectingSink();
        using var factory = new LoggingFactory(sink);

        for (var i = 0; i < 5; i++) await factory.CreateClient().GetAsync("/api/v1/health");

        Assert.DoesNotContain(sink.Events, e => Text(e, "RequestPath") == "/api/v1/health" && e.Level >= LogEventLevel.Information);
    }
}

using Serilog;
using Serilog.Context;
using Serilog.Events;
using ServNova.Api.Observability;

namespace ServNova.Api.Logging;

/// <summary>
/// Structured logging (Serilog). Every line of a request carries its <c>TraceId</c>, the same value
/// the error answers return. Levels and sinks can be changed through the "Serilog" configuration
/// section (environment variables such as <c>Serilog__MinimumLevel__Default=Warning</c>).
/// </summary>
public static class LoggingSetup
{
    private const string HealthPath = "/api/v1/health";

    public static WebApplicationBuilder AddServNovaLogging(this WebApplicationBuilder builder)
    {
        builder.Host.UseSerilog((context, services, logger) => logger
            .MinimumLevel.Information()
            .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
            .ReadFrom.Configuration(context.Configuration)
            .ReadFrom.Services(services)
            .Enrich.FromLogContext()
            .WriteTo.Console(outputTemplate:
                "[{Timestamp:HH:mm:ss} {Level:u3}] {TraceId} {Message:lj}{NewLine}{Exception}"));
        return builder;
    }

    /// <summary>Must be the first middleware, so that errors handled further down are logged with the TraceId.</summary>
    public static WebApplication UseServNovaRequestLogging(this WebApplication app)
    {
        app.Use(async (http, next) =>
        {
            using (LogContext.PushProperty("TraceId", TraceIds.Of(http)))
            {
                await next();
            }
        });

        app.UseSerilogRequestLogging(options => options.GetLevel = (http, _, exception) =>
            exception is not null || http.Response.StatusCode >= StatusCodes.Status500InternalServerError
                ? LogEventLevel.Error
                // Monitoring probes would flood the logs.
                : http.Request.Path.StartsWithSegments(HealthPath)
                    ? LogEventLevel.Verbose
                    : LogEventLevel.Information);
        return app;
    }
}

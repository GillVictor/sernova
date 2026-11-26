using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace ServNova.Api.RateLimiting;

public static class RateLimitPolicies
{
    /// <summary>Apply with <c>[EnableRateLimiting(RateLimitPolicies.Strict)]</c> on sensitive routes.</summary>
    public const string Strict = "strict";
}

public static class RateLimitingSetup
{
    private const string HealthPath = "/api/v1/health";

    public static IServiceCollection AddServNovaRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<RateLimitSettings>().Bind(configuration.GetSection(RateLimitSettings.Section));
        services.AddRateLimiter(_ => { });
        // Configured after the whole configuration is known (environment variables, tests).
        services.AddOptions<RateLimiterOptions>().Configure<IOptions<RateLimitSettings>>((options, settings) =>
            Configure(options, settings.Value));
        return services;
    }

    private static void Configure(RateLimiterOptions options, RateLimitSettings settings)
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

        options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(http =>
            // Monitoring must keep working: the health route is never limited.
            http.Request.Path.StartsWithSegments(HealthPath)
                ? RateLimitPartition.GetNoLimiter("health")
                : RateLimitPartition.GetFixedWindowLimiter(ClientKey(http), _ => FixedWindow(settings.Global)));

        options.AddPolicy(RateLimitPolicies.Strict, http =>
            RateLimitPartition.GetFixedWindowLimiter(ClientKey(http), _ => FixedWindow(settings.Strict)));

        options.OnRejected = async (context, cancellationToken) =>
        {
            var response = context.HttpContext.Response;
            response.StatusCode = StatusCodes.Status429TooManyRequests;
            if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
                response.Headers.RetryAfter = Math.Max(1, (int)Math.Ceiling(retryAfter.TotalSeconds)).ToString(System.Globalization.CultureInfo.InvariantCulture);

            var problems = context.HttpContext.RequestServices.GetRequiredService<IProblemDetailsService>();
            await problems.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = context.HttpContext,
                ProblemDetails = { Status = StatusCodes.Status429TooManyRequests },
            });
        };
    }

    // Behind a reverse proxy the forwarded client address must be configured (S1-T0 follow-up).
    private static string ClientKey(HttpContext http) => http.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    private static FixedWindowRateLimiterOptions FixedWindow(LimitSettings limit) => new()
    {
        PermitLimit = Math.Max(1, limit.PermitLimit),
        Window = TimeSpan.FromSeconds(Math.Max(1, limit.WindowSeconds)),
        QueueLimit = 0,
        AutoReplenishment = true,
    };
}

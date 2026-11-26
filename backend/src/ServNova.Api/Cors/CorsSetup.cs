using Microsoft.AspNetCore.Cors.Infrastructure;
using Microsoft.Extensions.Options;

namespace ServNova.Api.Cors;

public static class CorsSetup
{
    public static IServiceCollection AddServNovaCors(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<CorsSettings>()
            .Bind(configuration.GetSection(CorsSettings.Section))
            .Validate(
                s => s.AllowedOrigins.All(CorsSettings.IsValidOrigin),
                "Cors:AllowedOrigins must contain only origins like https://host[:port] (http only for localhost), never '*'.")
            .ValidateOnStart(); // a bad value stops the startup instead of silently opening or closing CORS

        services.AddCors();
        services.AddOptions<CorsOptions>().Configure<IOptions<CorsSettings>>((options, settings) =>
            options.AddDefaultPolicy(policy =>
            {
                var origins = settings.Value.AllowedOrigins;
                if (origins.Length == 0) return; // fail closed: no origin allowed
                policy.WithOrigins(origins)
                    .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
                    // Headers named by the contract: Bearer token, JSON, Idempotency-Key, If-Match.
                    .WithHeaders("Authorization", "Content-Type", "Idempotency-Key", "If-Match")
                    .WithExposedHeaders("ETag", "Retry-After")
                    .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
            }));
        return services;
    }
}

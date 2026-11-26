namespace ServNova.Api.OpenApi;

/// <summary>
/// OpenAPI document at <c>/openapi/v1.json</c>. Served in Development, and in other environments
/// only when <c>OpenApi__Enabled=true</c>: the schema of a production API is not published by default.
/// </summary>
public static class OpenApiSetup
{
    public static IServiceCollection AddServNovaOpenApi(this IServiceCollection services)
    {
        services.AddOpenApi();
        return services;
    }

    public static WebApplication MapServNovaOpenApi(this WebApplication app)
    {
        if (app.Environment.IsDevelopment() || app.Configuration.GetValue<bool>("OpenApi:Enabled"))
            app.MapOpenApi();
        return app;
    }
}

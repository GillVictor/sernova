using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;

namespace ServNova.Api.Tests;

/// <summary>API under test, plus the controllers of this test assembly (see <see cref="FailureController"/>).</summary>
public sealed class ApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(Microsoft.AspNetCore.Hosting.IWebHostBuilder builder) =>
        builder.ConfigureServices(services =>
            services.AddControllers().AddApplicationPart(typeof(FailureController).Assembly));
}

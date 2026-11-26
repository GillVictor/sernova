using ServNova.Api.Cors;
using ServNova.Api.Errors;
using ServNova.Api.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddProblemDetails(options => options.CustomizeProblemDetails = ProblemDetailsSetup.Customize);
builder.Services.AddServNovaCors(builder.Configuration);
builder.Services.AddServNovaRateLimiting(builder.Configuration);

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors(); // before the rate limiter: a preflight must not use up the quota
app.UseRateLimiter();
app.MapControllers();

app.Run();

// Makes the entry point visible to WebApplicationFactory<Program> in the tests.
public partial class Program;

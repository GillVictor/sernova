using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace ServNova.Api.Tests;

/// <summary>Test-only routes to observe the global and the "strict" rate limits.</summary>
[ApiController]
[Route("api/v1/_test")]
public sealed class TestRoutesController : ControllerBase
{
    [HttpGet("ping")]
    public IActionResult Ping() => Ok(new { pong = true });

    [HttpGet("strict")]
    [EnableRateLimiting("strict")]
    public IActionResult Strict() => Ok(new { pong = true });
}

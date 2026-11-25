using Microsoft.AspNetCore.Mvc;

namespace ServNova.Api.Tests;

/// <summary>Test-only route that fails on purpose. It exists only in the test assembly.</summary>
[ApiController]
[Route("api/v1/_test")]
public sealed class FailureController : ControllerBase
{
    public const string SecretMessage = "secret internal detail";

    [HttpGet("boom")]
    public IActionResult Boom() => throw new InvalidOperationException(SecretMessage);
}

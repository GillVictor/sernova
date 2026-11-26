namespace ServNova.Api.RateLimiting;

/// <summary>One fixed-window limit: at most <see cref="PermitLimit"/> requests per window.</summary>
public sealed class LimitSettings
{
    public int PermitLimit { get; set; }
    public int WindowSeconds { get; set; }
}

/// <summary>
/// Rate limits, read from the "RateLimiting" configuration section (environment variables
/// <c>RateLimiting__Global__PermitLimit</c>, etc.). The contract fixes no numbers (OP-38):
/// these defaults are provisional.
/// </summary>
public sealed class RateLimitSettings
{
    public const string Section = "RateLimiting";

    /// <summary>Every route, per client address.</summary>
    public LimitSettings Global { get; set; } = new() { PermitLimit = 100, WindowSeconds = 60 };

    /// <summary>Sensitive routes (login, SMS code, handover code, requests and orders creation).</summary>
    public LimitSettings Strict { get; set; } = new() { PermitLimit = 5, WindowSeconds = 60 };
}

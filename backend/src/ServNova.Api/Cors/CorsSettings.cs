namespace ServNova.Api.Cors;

/// <summary>
/// Browser origins allowed to call the API (the Next.js administration). Read from the "Cors"
/// configuration section, e.g. <c>Cors__AllowedOrigins__0=https://admin.servnova.example</c>.
/// Empty by default: no origin is allowed. The mobile app does not use CORS.
/// </summary>
public sealed class CorsSettings
{
    public const string Section = "Cors";

    public string[] AllowedOrigins { get; set; } = [];

    /// <summary>
    /// An origin is scheme + host (+ port), nothing else. HTTPS only (contract: "HTTPS uniquement"),
    /// except plain http on localhost for local development. Never "*".
    /// </summary>
    public static bool IsValidOrigin(string? origin)
    {
        if (string.IsNullOrWhiteSpace(origin) || !Uri.TryCreate(origin, UriKind.Absolute, out var uri)) return false;
        if (uri.GetLeftPart(UriPartial.Authority) != origin) return false; // no path, query, fragment or trailing slash
        if (!string.IsNullOrEmpty(uri.UserInfo)) return false;
        return uri.Scheme == Uri.UriSchemeHttps
            || (uri.Scheme == Uri.UriSchemeHttp && (uri.Host is "localhost" or "127.0.0.1"));
    }
}

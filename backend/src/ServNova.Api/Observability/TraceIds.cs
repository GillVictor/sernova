using System.Diagnostics;

namespace ServNova.Api.Observability;

/// <summary>
/// The request's trace id. The same value goes into the error answers (<c>traceId</c>) and into
/// every log line of the request, so a support ticket can be matched with the logs.
/// </summary>
public static class TraceIds
{
    public static string Of(HttpContext http) =>
        Activity.Current?.TraceId.ToString() ?? http.TraceIdentifier;
}

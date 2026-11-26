using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ServNova.Api.Observability;

namespace ServNova.Api.Errors;

/// <summary>
/// Gives every error answer the contract format: problem+json (RFC 9457) with a stable
/// <c>code</c> and a <c>traceId</c> (the same id the logs carry).
/// </summary>
public static class ProblemDetailsSetup
{
    // Messages in French, as in the "Erreurs" sheet.
    private static readonly Dictionary<int, (string Code, string Title)> Known = new()
    {
        [StatusCodes.Status401Unauthorized] = (ErrorCodes.Unauthenticated, "Authentification requise"),
        [StatusCodes.Status403Forbidden] = (ErrorCodes.Forbidden, "Accès refusé"),
        [StatusCodes.Status404NotFound] = (ErrorCodes.NotFound, "Ressource introuvable"),
        [StatusCodes.Status429TooManyRequests] = (ErrorCodes.RateLimited, "Trop de requêtes"),
        [StatusCodes.Status500InternalServerError] = (ErrorCodes.InternalError, "Erreur interne"),
    };

    public static void Customize(ProblemDetailsContext context)
    {
        var problem = context.ProblemDetails;
        var status = problem.Status ?? context.HttpContext.Response.StatusCode;

        // A server error never exposes details: only the code and the trace id.
        if (status >= StatusCodes.Status500InternalServerError)
        {
            problem.Detail = null;
            problem.Extensions.Clear();
        }

        if (Known.TryGetValue(status, out var known))
        {
            problem.Title = known.Title;
            problem.Extensions["code"] = known.Code;
        }

        problem.Extensions["traceId"] = TraceIds.Of(context.HttpContext);
    }
}

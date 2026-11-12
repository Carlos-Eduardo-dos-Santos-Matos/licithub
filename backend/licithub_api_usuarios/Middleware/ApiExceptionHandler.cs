using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace licithub_api_usuarios.Middleware;

internal sealed class ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (status, title, detail) = exception switch
        {
            InvalidOperationException => (
                StatusCodes.Status409Conflict,
                "Conflito",
                "A operação não pôde ser concluída porque os dados já existem ou estão em conflito."),
            KeyNotFoundException => (
                StatusCodes.Status404NotFound,
                "Não encontrado",
                "O recurso solicitado não foi encontrado."),
            _ => (0, string.Empty, string.Empty)
        };

        if (status == 0)
            return false;

        logger.LogWarning(exception, "Erro de domínio tratado: {Title}", title);
        httpContext.Response.StatusCode = status;
        await httpContext.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Status = status,
            Title = title,
            Detail = detail,
            Instance = httpContext.Request.Path
        }, cancellationToken);
        return true;
    }
}

// Program - composicao da API, CORS restrito, limite de taxa e endpoint do dashboard
using licithub_api_empresas.Services;
using Microsoft.AspNetCore.RateLimiting;
using MySqlConnector;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(origem =>
                Uri.TryCreate(origem, UriKind.Absolute, out var uri) && uri.IsLoopback);
        }
        else
        {
            var origens = builder.Configuration.GetSection("Cors:OrigensPermitidas").Get<string[]>() ?? [];
            policy.WithOrigins(origens);
        }
        policy.AllowAnyMethod().AllowAnyHeader();
    });
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("padrao", limitador =>
    {
        limitador.PermitLimit = 30;
        limitador.Window = TimeSpan.FromMinutes(1);
        limitador.QueueLimit = 0;
    });
});

builder.Services.AddHttpClient<PncpService>(cliente =>
{
    cliente.BaseAddress = new Uri("https://pncp.gov.br/api/consulta/");
    cliente.DefaultRequestHeaders.Add("Accept", "application/json");
    cliente.DefaultRequestHeaders.Add("User-Agent", "LicitHub/1.0 (projeto academico Fatec)");
});
builder.Services.AddSingleton<EditalRepository>();
builder.Services.AddHostedService<SincronizacaoPncpService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseCors("Frontend");
app.UseRateLimiter();

app.MapGet("/api/dashboard", async (EditalRepository repository, ILogger<Program> logger) =>
{
    try
    {
        var metricas = await repository.ObterMetricasDashboardAsync();

        var alerta = string.IsNullOrEmpty(metricas.UltimoOrgao)
            ? "Nenhuma licitação encontrada no banco."
            : $"Publicação mais recente importada: {metricas.UltimoOrgao}";

        return Results.Ok(new
        {
            licitacoesAtivas = metricas.Ativas,
            disputasGanhas = metricas.TotalGanho,
            alerta
        });
    }
    catch (MySqlException ex)
    {
        logger.LogError(ex, "Falha ao consultar as métricas do dashboard");
        return Results.Problem(
            title: "Banco de dados indisponível",
            detail: "Não foi possível consultar as métricas do dashboard.",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
}).RequireRateLimiting("padrao");

app.Run();

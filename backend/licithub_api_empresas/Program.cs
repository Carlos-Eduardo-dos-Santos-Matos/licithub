using licithub_api_empresas.Services;

var builder = WebApplication.CreateBuilder(args);

// Configuração CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy => 
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

builder.Services.AddHttpClient<PncpService>();
builder.Services.AddSingleton<EditalRepository>();

var app = builder.Build();
app.UseCors("AllowFlutter");

// Endpoint Dashboard 100% Dinâmico do MySQL + PNCP
app.MapGet("/api/dashboard", async (PncpService pncpService, EditalRepository repository) =>
{
    // 1. Ingestão real do PNCP
    var dadosGov = await pncpService.ObterEditaisAbertosAsync();
    if (dadosGov?.Data != null && dadosGov.Data.Any())
    {
        await repository.SalvarEditaisAsync(dadosGov.Data);
    }

    // 2. Consulta de métricas reais no banco
    var (ativas, totalGanho, ultimoOrgao) = await repository.ObterMetricasDashboardAsync();

    string alertaDinamico = string.IsNullOrEmpty(ultimoOrgao)
        ? "Nenhuma licitação encontrada no banco."
        : $"Último edital real importado: {ultimoOrgao}";

    return Results.Ok(new
    {
        licitacoesAtivas = ativas,
        disputasGanhas = totalGanho.ToString("C2"), // Retorna R$ 0,00 se não houver vitórias registradas
        alerta = alertaDinamico
    });
});

app.Run();
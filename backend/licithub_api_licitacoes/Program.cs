using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
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
        limitador.PermitLimit = 120;
        limitador.Window = TimeSpan.FromMinutes(1);
        limitador.QueueLimit = 0;
    });
});

builder.Services.AddHttpClient<PncpService>(cliente =>
{
    cliente.BaseAddress = new Uri("https://pncp.gov.br/api/consulta/");
    cliente.Timeout = TimeSpan.FromSeconds(45);
    cliente.DefaultRequestHeaders.Add("Accept", "application/json");
    cliente.DefaultRequestHeaders.Add("User-Agent", "LicitHub/1.0");
});

builder.Services.AddSingleton<EditalRepository>();
builder.Services.AddSingleton<SincronizacaoPncpService>();
builder.Services.AddHostedService(sp => sp.GetRequiredService<SincronizacaoPncpService>());

var app = builder.Build();

if (!app.Environment.IsDevelopment())
    app.UseHttpsRedirection();

app.UseCors("Frontend");
app.UseRateLimiter();

var jwtKey = builder.Configuration["Jwt:Key"] ?? "LicitHub_ChaveSecreta_Producao_2026_TCC_99!";

(long idUsuario, long idEmpresa)? ExtrairSessao(HttpRequest request)
{
    var auth = request.Headers.Authorization.ToString();
    if (string.IsNullOrWhiteSpace(auth) || !auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        return null;

    var token = auth["Bearer ".Length..].Trim();
    var partes = token.Split('.');
    if (partes.Length != 3)
        return null;

    try
    {
        var payloadAssinado = Encoding.UTF8.GetBytes($"{partes[0]}.{partes[1]}");
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(jwtKey));
        var assinaturaCalculada = Base64UrlEncode(hmac.ComputeHash(payloadAssinado));
        if (assinaturaCalculada != partes[2])
            return null;

        var jsonBytes = Base64UrlDecode(partes[1]);
        using var doc = JsonDocument.Parse(jsonBytes);
        var root = doc.RootElement;

        long idUsuario = 0;
        if (root.TryGetProperty("sub", out var subEl) && long.TryParse(subEl.GetString(), out var u))
            idUsuario = u;

        long idEmpresa = 0;
        if (root.TryGetProperty("id_empresa", out var empEl) && long.TryParse(empEl.GetString(), out var e))
            idEmpresa = e;

        return idUsuario > 0 ? (idUsuario, idEmpresa) : null;
    }
    catch
    {
        return null;
    }
}

app.MapGet("/api/dashboard", async (HttpRequest req, EditalRepository repository, ILogger<Program> logger) =>
{
    try
    {
        var sessao = ExtrairSessao(req);
        var dashboard = await repository.ObterDashboardCompletoAsync(sessao?.idEmpresa);
        return Results.Ok(dashboard);
    }
    catch (MySqlException ex)
    {
        logger.LogError(ex, "Falha ao consultar métricas do dashboard");
        return Results.Problem(title: "Banco de dados indisponível", detail: ex.Message, statusCode: 503);
    }
}).RequireRateLimiting("padrao");

app.MapPost("/api/sincronizar", async (SincronizacaoPncpService syncService, CancellationToken ct) =>
{
    var resultado = await syncService.SincronizarAgoraAsync(ct);
    return resultado.Sucesso ? Results.Ok(resultado) : Results.Problem(title: "Falha na sincronização PNCP", detail: resultado.Mensagem, statusCode: 502);
}).RequireRateLimiting("padrao");

app.MapGet("/api/licitacoes", async (
    EditalRepository repository,
    string? q,
    string? uf,
    decimal? valorMin,
    string? modalidade,
    string? situacao,
    string? municipio,
    int pagina = 1,
    int tamanhoPagina = 20) =>
{
    var resultado = await repository.BuscarLicitacoesAsync(
        q, uf, valorMin, modalidade, situacao, municipio, pagina, tamanhoPagina);
    return Results.Ok(resultado);
}).RequireRateLimiting("padrao");

app.MapGet("/api/licitacoes/{id:long}", async (
    long id,
    EditalRepository repository,
    PncpService pncpService,
    CancellationToken ct) =>
{
    var detalhe = await repository.ObterLicitacaoDetalheAsync(id, pncpService, ct);
    return detalhe is null ? Results.NotFound(new { mensagem = "Licitação não encontrada." }) : Results.Ok(detalhe);
}).RequireRateLimiting("padrao");

app.MapGet("/api/acompanhamentos", async (HttpRequest req, EditalRepository repository) =>
{
    var sessao = ExtrairSessao(req);
    if (sessao is null || sessao.Value.idEmpresa <= 0)
        return Results.Unauthorized();

    var lista = await repository.ListarAcompanhamentosAsync(sessao.Value.idEmpresa);
    return Results.Ok(lista);
}).RequireRateLimiting("padrao");

app.MapPost("/api/acompanhamentos", async (
    HttpRequest req,
    AdicionarAcompanhamentoRequest body,
    EditalRepository repository) =>
{
    var sessao = ExtrairSessao(req);
    if (sessao is null || sessao.Value.idEmpresa <= 0)
        return Results.Unauthorized();

    var id = await repository.AdicionarAcompanhamentoAsync(
        sessao.Value.idEmpresa, sessao.Value.idUsuario, body.IdLicitacao, body.Anotacoes);
    return Results.Ok(new { idAcompanhamento = id });
}).RequireRateLimiting("padrao");

app.MapPatch("/api/acompanhamentos/{id:long}/status", async (
    long id,
    HttpRequest req,
    AtualizarStatusAcompanhamentoRequest body,
    EditalRepository repository) =>
{
    var sessao = ExtrairSessao(req);
    if (sessao is null || sessao.Value.idEmpresa <= 0)
        return Results.Unauthorized();

    var ok = await repository.AtualizarStatusAcompanhamentoAsync(
        sessao.Value.idEmpresa, sessao.Value.idUsuario, id, body.Status, body.Observacao);
    return ok ? Results.NoContent() : Results.NotFound();
}).RequireRateLimiting("padrao");

app.Run();

static string Base64UrlEncode(byte[] input)
    => Convert.ToBase64String(input).TrimEnd('=').Replace('+', '-').Replace('/', '_');

static byte[] Base64UrlDecode(string input)
{
    var base64 = input.Replace('-', '+').Replace('_', '/');
    switch (base64.Length % 4)
    {
        case 2: base64 += "=="; break;
        case 3: base64 += "="; break;
    }
    return Convert.FromBase64String(base64);
}

public record AdicionarAcompanhamentoRequest(long IdLicitacao, string? Anotacoes);
public record AtualizarStatusAcompanhamentoRequest(string Status, string? Observacao);
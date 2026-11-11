// SincronizacaoPncpService - ingestao periodica do PNCP em servico de fundo, fora dos endpoints
namespace licithub_api_empresas.Services;

public class SincronizacaoPncpService : BackgroundService
{
    private static readonly SemaphoreSlim Trava = new(1, 1);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SincronizacaoPncpService> _logger;

    public SincronizacaoPncpService(
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        ILogger<SincronizacaoPncpService> logger)
    {
        _scopeFactory = scopeFactory;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var intervaloMinutos = Math.Max(5, _configuration.GetValue("Pncp:IntervaloMinutos", 60));
        var intervalo = TimeSpan.FromMinutes(intervaloMinutos);

        await SincronizarAsync(stoppingToken);

        using var temporizador = new PeriodicTimer(intervalo);
        while (await temporizador.WaitForNextTickAsync(stoppingToken))
        {
            await SincronizarAsync(stoppingToken);
        }
    }

    private async Task SincronizarAsync(CancellationToken cancellationToken)
    {
        if (!await Trava.WaitAsync(TimeSpan.Zero, cancellationToken))
        {
            _logger.LogInformation("Sincronização anterior ainda em execução; ciclo ignorado");
            return;
        }

        try
        {
            using var escopo = _scopeFactory.CreateScope();
            var pncp = escopo.ServiceProvider.GetRequiredService<PncpService>();
            var repositorio = escopo.ServiceProvider.GetRequiredService<EditalRepository>();

            var contratacoes = await pncp.ObterContratacoesComPropostaAbertaAsync(cancellationToken);
            if (contratacoes.Count == 0)
            {
                _logger.LogInformation("Sincronização sem registros para gravar");
                return;
            }

            var resultado = await repositorio.SalvarEditaisAsync(contratacoes, cancellationToken);
            _logger.LogInformation(
                "Sincronização concluída: {Gravados} gravados, {Descartados} descartados por falta de dados obrigatórios",
                resultado.Gravados, resultado.Descartados);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Falha na sincronização com o PNCP");
        }
        finally
        {
            Trava.Release();
        }
    }
}

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

        await SincronizarAgoraAsync(stoppingToken);

        using var temporizador = new PeriodicTimer(intervalo);
        while (await temporizador.WaitForNextTickAsync(stoppingToken))
        {
            await SincronizarAgoraAsync(stoppingToken);
        }
    }

    public async Task<ResultadoSincronizacaoDto> SincronizarAgoraAsync(CancellationToken cancellationToken)
    {
        if (!await Trava.WaitAsync(TimeSpan.Zero, cancellationToken))
        {
            return new ResultadoSincronizacaoDto(false, "Sincronização já está em andamento.", 0, 0, 0);
        }

        long idExecucao = 0;
        try
        {
            using var escopo = _scopeFactory.CreateScope();
            var pncp = escopo.ServiceProvider.GetRequiredService<PncpService>();
            var repositorio = escopo.ServiceProvider.GetRequiredService<EditalRepository>();

            idExecucao = await repositorio.IniciarExecucaoSyncAsync(cancellationToken);

            var contratacoes = await pncp.ObterContratacoesComPropostaAbertaAsync(cancellationToken);
            if (contratacoes.Count == 0)
            {
                await repositorio.FinalizarExecucaoSyncAsync(idExecucao, "PARCIAL", 0, 0, "PNCP retornou 0 registros na janela.", cancellationToken);
                return new ResultadoSincronizacaoDto(true, "PNCP retornou 0 registros novos na janela consultada.", 0, 0, 0);
            }

            var resultado = await repositorio.SalvarEditaisAsync(contratacoes, cancellationToken);
            await repositorio.FinalizarExecucaoSyncAsync(idExecucao, "SUCESSO", contratacoes.Count, resultado.Gravados, null, cancellationToken);

            _logger.LogInformation("Sincronização PNCP concluída: {Lidos} lidos, {Gravados} gravados, {Descartados} descartados",
                contratacoes.Count, resultado.Gravados, resultado.Descartados);

            return new ResultadoSincronizacaoDto(
                true,
                $"Sincronização concluída: {resultado.Gravados} editais gravados no MySQL.",
                contratacoes.Count,
                resultado.Gravados,
                resultado.Descartados);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Falha na sincronização com o PNCP");
            if (idExecucao > 0)
            {
                using var escopo = _scopeFactory.CreateScope();
                var repositorio = escopo.ServiceProvider.GetRequiredService<EditalRepository>();
                await repositorio.FinalizarExecucaoSyncAsync(idExecucao, "FALHA", 0, 0, ex.Message, CancellationToken.None);
            }
            return new ResultadoSincronizacaoDto(false, $"Erro ao sincronizar PNCP: {ex.Message}", 0, 0, 0);
        }
        finally
        {
            Trava.Release();
        }
    }
}

public record ResultadoSincronizacaoDto(
    bool Sucesso,
    string Mensagem,
    int Lidos,
    int Gravados,
    int Descartados);
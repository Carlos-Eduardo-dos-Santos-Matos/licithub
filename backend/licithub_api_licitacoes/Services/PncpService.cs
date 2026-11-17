using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace licithub_api_empresas.Services;

public class PncpService
{
    private static readonly JsonSerializerOptions OpcoesJson = new()
    {
        PropertyNameCaseInsensitive = true,
        NumberHandling = JsonNumberHandling.AllowReadingFromString
    };

    private static readonly TimeZoneInfo FusoBrasilia =
        TimeZoneInfo.FindSystemTimeZoneById("America/Sao_Paulo");

    private readonly HttpClient _httpClient;
    private readonly ILogger<PncpService> _logger;
    private readonly int[] _modalidades;
    private readonly int _diasJanelaProposta;
    private readonly int _tamanhoPagina;
    private readonly int _maxPaginasPorModalidade;

    public PncpService(HttpClient httpClient, IConfiguration configuration, ILogger<PncpService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _modalidades = configuration.GetSection("Pncp:Modalidades").Get<int[]>() ?? [6, 8];
        _diasJanelaProposta = Math.Clamp(configuration.GetValue("Pncp:DiasJanelaProposta", 30), 1, 90);
        _tamanhoPagina = Math.Clamp(configuration.GetValue("Pncp:TamanhoPagina", 50), 10, 50);
        _maxPaginasPorModalidade = Math.Max(1, configuration.GetValue("Pncp:MaxPaginasPorModalidade", 5));
    }

    public async Task<List<ContratacaoPncp>> ObterContratacoesComPropostaAbertaAsync(CancellationToken cancellationToken)
    {
        var mapa = new Dictionary<string, ContratacaoPncp>(StringComparer.OrdinalIgnoreCase);
        var hoje = HojeEmBrasilia();
        var dataFinalProposta = hoje.AddDays(_diasJanelaProposta).ToString("yyyyMMdd");

        foreach (var modalidade in _modalidades)
        {
            var pagina = 1;
            var totalPaginas = 1;

            do
            {
                var endpoint = $"v1/contratacoes/proposta?dataFinal={dataFinalProposta}" +
                               $"&codigoModalidadeContratacao={modalidade}" +
                               $"&pagina={pagina}&tamanhoPagina={_tamanhoPagina}";

                var resposta = await _httpClient.GetAsync(endpoint, cancellationToken);

                if (resposta.StatusCode == HttpStatusCode.NoContent)
                    break;

                resposta.EnsureSuccessStatusCode();

                var corpo = await resposta.Content.ReadAsStringAsync(cancellationToken);
                if (string.IsNullOrWhiteSpace(corpo))
                    break;

                var paginaResposta = JsonSerializer.Deserialize<PncpRespostaPagina>(corpo, OpcoesJson);
                if (paginaResposta?.Data is null || paginaResposta.Data.Count == 0)
                    break;

                foreach (var item in paginaResposta.Data)
                {
                    var dados = item.Deserialize<ContratacaoPncpDto>(OpcoesJson);
                    if (dados?.NumeroControlePncp is not null)
                    {
                        mapa[dados.NumeroControlePncp] = new ContratacaoPncp(dados, item.GetRawText());
                    }
                }

                totalPaginas = paginaResposta.TotalPaginas;
                if (pagina >= _maxPaginasPorModalidade)
                    break;

                pagina++;
            } while (pagina <= totalPaginas);
        }

        // Busca complementar por data de publicação (últimos 7 dias) para garantir resultados recentes
        var dataInicialPub = hoje.AddDays(-7).ToString("yyyyMMdd");
        var dataFinalPub = hoje.ToString("yyyyMMdd");
        foreach (var modalidade in _modalidades)
        {
            var endpointPub = $"v1/contratacoes/publicacao?dataInicial={dataInicialPub}&dataFinal={dataFinalPub}" +
                              $"&codigoModalidadeContratacao={modalidade}&pagina=1&tamanhoPagina={_tamanhoPagina}";

            var respPub = await _httpClient.GetAsync(endpointPub, cancellationToken);
            if (!respPub.IsSuccessStatusCode || respPub.StatusCode == HttpStatusCode.NoContent)
                continue;

            var corpoPub = await respPub.Content.ReadAsStringAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(corpoPub))
                continue;

            var paginaPub = JsonSerializer.Deserialize<PncpRespostaPagina>(corpoPub, OpcoesJson);
            if (paginaPub?.Data is null)
                continue;

            foreach (var item in paginaPub.Data)
            {
                var dados = item.Deserialize<ContratacaoPncpDto>(OpcoesJson);
                if (dados?.NumeroControlePncp is not null && !mapa.ContainsKey(dados.NumeroControlePncp))
                {
                    mapa[dados.NumeroControlePncp] = new ContratacaoPncp(dados, item.GetRawText());
                }
            }
        }

        _logger.LogInformation("PNCP: {Quantidade} contratações únicas obtidas", mapa.Count);
        return mapa.Values.ToList();
    }

    public async Task<List<ItemLicitacaoPncpDto>> ObterItensContratacaoAsync(
        string numeroControlePncp, CancellationToken cancellationToken)
    {
        // Formato esperado: CNPJ-1-SEQUENCIAL/ANO (ex: 36922587000133-1-000007/2026)
        var partesBarra = numeroControlePncp.Split('/');
        if (partesBarra.Length != 2 || !int.TryParse(partesBarra[1], out var ano))
            return [];

        var partesTraco = partesBarra[0].Split('-');
        if (partesTraco.Length < 3 || !int.TryParse(partesTraco[2], out var sequencial))
            return [];

        var cnpj = partesTraco[0];
        var urlItens = $"https://pncp.gov.br/api/pncp/v1/orgaos/{cnpj}/compras/{ano}/{sequencial}/itens?pagina=1&tamanhoPagina=50";

        var resposta = await _httpClient.GetAsync(urlItens, cancellationToken);
        if (!resposta.IsSuccessStatusCode || resposta.StatusCode == HttpStatusCode.NoContent)
            return [];

        var json = await resposta.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(json))
            return [];

        return JsonSerializer.Deserialize<List<ItemLicitacaoPncpDto>>(json, OpcoesJson) ?? [];
    }

    public static DateTime HojeEmBrasilia()
        => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, FusoBrasilia).Date;

    public static DateTime? HorarioBrasiliaParaUtc(DateTime? horarioBrasilia)
    {
        if (horarioBrasilia is null)
            return null;

        var semFuso = DateTime.SpecifyKind(horarioBrasilia.Value, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(semFuso, FusoBrasilia);
    }
}

public class PncpRespostaPagina
{
    [JsonPropertyName("totalRegistros")]
    public int TotalRegistros { get; set; }

    [JsonPropertyName("totalPaginas")]
    public int TotalPaginas { get; set; }

    [JsonPropertyName("data")]
    public List<JsonElement>? Data { get; set; }
}

public record ContratacaoPncp(ContratacaoPncpDto Dados, string PayloadBruto);

public class ContratacaoPncpDto
{
    [JsonPropertyName("numeroControlePNCP")]
    public string? NumeroControlePncp { get; set; }

    [JsonPropertyName("numeroCompra")]
    public string? NumeroCompra { get; set; }

    [JsonPropertyName("anoCompra")]
    public int? AnoCompra { get; set; }

    [JsonPropertyName("modalidadeId")]
    public int? ModalidadeId { get; set; }

    [JsonPropertyName("modalidadeNome")]
    public string? ModalidadeNome { get; set; }

    [JsonPropertyName("modoDisputaNome")]
    public string? ModoDisputaNome { get; set; }

    [JsonPropertyName("situacaoCompraNome")]
    public string? SituacaoNome { get; set; }

    [JsonPropertyName("objetoCompra")]
    public string? Objeto { get; set; }

    [JsonPropertyName("valorTotalEstimado")]
    public decimal? ValorEstimado { get; set; }

    [JsonPropertyName("dataPublicacaoPncp")]
    public DateTime? DataPublicacao { get; set; }

    [JsonPropertyName("dataAberturaProposta")]
    public DateTime? DataAberturaProposta { get; set; }

    [JsonPropertyName("dataEncerramentoProposta")]
    public DateTime? DataEncerramentoProposta { get; set; }

    [JsonPropertyName("linkSistemaOrigem")]
    public string? LinkOrigem { get; set; }

    [JsonPropertyName("orgaoEntidade")]
    public OrgaoPncpDto? Orgao { get; set; }

    [JsonPropertyName("unidadeOrgao")]
    public UnidadeOrgaoPncpDto? Unidade { get; set; }

    public string? NumeroEdital => string.IsNullOrWhiteSpace(NumeroCompra)
        ? null
        : AnoCompra is null ? NumeroCompra : $"{NumeroCompra}/{AnoCompra}";
}

public class OrgaoPncpDto
{
    [JsonPropertyName("cnpj")]
    public string? Cnpj { get; set; }

    [JsonPropertyName("razaoSocial")]
    public string? RazaoSocial { get; set; }

    [JsonPropertyName("esferaId")]
    public string? EsferaId { get; set; }
}

public class UnidadeOrgaoPncpDto
{
    [JsonPropertyName("ufSigla")]
    public string? UfSigla { get; set; }

    [JsonPropertyName("municipioNome")]
    public string? MunicipioNome { get; set; }
}

public class ItemLicitacaoPncpDto
{
    [JsonPropertyName("numeroItem")]
    public int NumeroItem { get; set; }

    [JsonPropertyName("descricao")]
    public string? Descricao { get; set; }

    [JsonPropertyName("quantidade")]
    public decimal? Quantidade { get; set; }

    [JsonPropertyName("unidadeMedida")]
    public string? UnidadeMedida { get; set; }

    [JsonPropertyName("valorUnitarioEstimado")]
    public decimal? ValorUnitarioEstimado { get; set; }

    [JsonPropertyName("tipoBeneficioNome")]
    public string? TipoBeneficioNome { get; set; }
}
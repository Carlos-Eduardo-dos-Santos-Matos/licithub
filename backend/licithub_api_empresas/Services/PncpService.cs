// PncpService - consulta paginada de contratacoes com proposta em aberto na API do PNCP
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
    private readonly int _tamanhoPagina;
    private readonly int _maxPaginasPorModalidade;

    public PncpService(HttpClient httpClient, IConfiguration configuration, ILogger<PncpService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _modalidades = configuration.GetSection("Pncp:Modalidades").Get<int[]>() ?? [6];
        _tamanhoPagina = Math.Clamp(configuration.GetValue("Pncp:TamanhoPagina", 50), 10, 50);
        _maxPaginasPorModalidade = Math.Max(1, configuration.GetValue("Pncp:MaxPaginasPorModalidade", 10));
    }

    public async Task<List<ContratacaoPncp>> ObterContratacoesComPropostaAbertaAsync(CancellationToken cancellationToken)
    {
        var contratacoes = new List<ContratacaoPncp>();
        var dataFinal = HojeEmBrasilia().ToString("yyyyMMdd");

        foreach (var modalidade in _modalidades)
        {
            var pagina = 1;
            var totalPaginas = 1;

            do
            {
                var endpoint = $"v1/contratacoes/proposta?dataFinal={dataFinal}" +
                               $"&codigoModalidadeContratacao={modalidade}" +
                               $"&pagina={pagina}&tamanhoPagina={_tamanhoPagina}";

                var resposta = await _httpClient.GetAsync(endpoint, cancellationToken);

                if (resposta.StatusCode == HttpStatusCode.NoContent)
                {
                    _logger.LogInformation("PNCP sem registros para a modalidade {Modalidade}", modalidade);
                    break;
                }

                resposta.EnsureSuccessStatusCode();

                var corpo = await resposta.Content.ReadAsStringAsync(cancellationToken);
                if (string.IsNullOrWhiteSpace(corpo))
                {
                    break;
                }

                var paginaResposta = JsonSerializer.Deserialize<PncpRespostaPagina>(corpo, OpcoesJson);
                if (paginaResposta?.Data is null || paginaResposta.Data.Count == 0)
                {
                    break;
                }

                foreach (var item in paginaResposta.Data)
                {
                    var dados = item.Deserialize<ContratacaoPncpDto>(OpcoesJson);
                    if (dados is not null)
                    {
                        contratacoes.Add(new ContratacaoPncp(dados, item.GetRawText()));
                    }
                }

                totalPaginas = paginaResposta.TotalPaginas;

                if (pagina >= _maxPaginasPorModalidade && pagina < totalPaginas)
                {
                    _logger.LogWarning(
                        "PNCP: modalidade {Modalidade} tem {TotalPaginas} páginas; importadas {Paginas} nesta execução",
                        modalidade, totalPaginas, pagina);
                    break;
                }

                pagina++;
            } while (pagina <= totalPaginas);
        }

        _logger.LogInformation("PNCP: {Quantidade} contratações obtidas", contratacoes.Count);
        return contratacoes;
    }

    public static DateTime HojeEmBrasilia()
        => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, FusoBrasilia).Date;

    public static DateTime? HorarioBrasiliaParaUtc(DateTime? horarioBrasilia)
    {
        if (horarioBrasilia is null)
        {
            return null;
        }

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

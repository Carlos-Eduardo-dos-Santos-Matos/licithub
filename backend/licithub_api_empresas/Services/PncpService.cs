using System.Text.Json;
using System.Text.Json.Serialization;

namespace licithub_api_empresas.Services;

public class PncpService
{
    private readonly HttpClient _httpClient;

    public PncpService(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("https://pncp.gov.br/api/consulta/");
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
        _httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
    }

    public async Task<PncpResponse?> ObterEditaisAbertosAsync()
    {
        try
        {
            var hoje = DateTime.Now;
            var dataInicial = hoje.AddDays(-30).ToString("yyyyMMdd");
            var dataFinal = hoje.ToString("yyyyMMdd");

            var endpoint = $"v1/contratacoes/publicacao?dataInicial={dataInicial}&dataFinal={dataFinal}&codigoModalidadeContratacao=6&pagina=1";

            Console.WriteLine($"[PNCP GET] https://pncp.gov.br/api/consulta/{endpoint}");

            var response = await _httpClient.GetAsync(endpoint);

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"[PNCP HTTP ERRO] Status: {response.StatusCode}");
                return null;
            }

            var jsonString = await response.Content.ReadAsStringAsync();

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true,
                NumberHandling = JsonNumberHandling.AllowReadingFromString
            };

            var resultado = JsonSerializer.Deserialize<PncpResponse>(jsonString, options);
            Console.WriteLine($"[PNCP SUCESSO] Editais capturados: {resultado?.Data?.Count ?? 0}");

            return resultado;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[PNCP EXCEÇÃO] Erro na consulta: {ex.Message}");
            return null;
        }
    }
}

public class PncpResponse
{
    [JsonPropertyName("totalRegistros")]
    public int TotalRegistros { get; set; }

    [JsonPropertyName("totalPaginas")]
    public int TotalPaginas { get; set; }

    [JsonPropertyName("data")]
    public List<EditalPncpDto> Data { get; set; } = new();
}

public class EditalPncpDto
{
    [JsonPropertyName("numeroContratacaoPNCP")]
    public string? NumeroPncp { get; set; }

    [JsonPropertyName("numeroContratacao")]
    public string? Numero { get; set; }

    // Propriedade que resolve o erro CS1061 no EditalRepository.cs
    public string CodigoIdentificador => !string.IsNullOrEmpty(NumeroPncp) 
        ? NumeroPncp 
        : (!string.IsNullOrEmpty(Numero) ? Numero : Guid.NewGuid().ToString());

    [JsonPropertyName("orgaoEntidade")]
    public OrgaoDto? Orgao { get; set; }

    [JsonPropertyName("objetoCompra")]
    public string? Objeto { get; set; }

    [JsonPropertyName("valorTotalEstimado")]
    public decimal? ValorEstimado { get; set; }
}

public class OrgaoDto
{
    [JsonPropertyName("razaoSocial")]
    public string? Nome { get; set; }
}
// EditalRepository - persistencia das licitacoes no esquema oficial db_licitacoes
using MySqlConnector;

namespace licithub_api_empresas.Services;

public class EditalRepository
{
    private static readonly HashSet<string> UfsValidas = new(StringComparer.OrdinalIgnoreCase)
    {
        "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG",
        "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
    };

    private readonly string _connectionString;

    public EditalRepository(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection não configurada. " +
                "Defina-a em variável de ambiente (ConnectionStrings__DefaultConnection) ou em dotnet user-secrets.");
        }

        _connectionString = connectionString;
    }

    public async Task<ResultadoGravacao> SalvarEditaisAsync(List<ContratacaoPncp> contratacoes, CancellationToken cancellationToken)
    {
        var gravados = 0;
        var descartados = 0;

        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync(cancellationToken);
        using var transacao = await conexao.BeginTransactionAsync(cancellationToken);

        var orgaosPorCnpj = new Dictionary<string, long>();

        foreach (var contratacao in contratacoes)
        {
            var dados = contratacao.Dados;
            var cnpjOrgao = SomenteAlfanumericos(dados.Orgao?.Cnpj);

            if (string.IsNullOrWhiteSpace(dados.NumeroControlePncp)
                || string.IsNullOrWhiteSpace(dados.Objeto)
                || dados.ModalidadeId is null
                || string.IsNullOrWhiteSpace(dados.ModalidadeNome)
                || string.IsNullOrWhiteSpace(dados.SituacaoNome)
                || string.IsNullOrWhiteSpace(dados.Orgao?.RazaoSocial)
                || cnpjOrgao.Length != 14)
            {
                descartados++;
                continue;
            }

            if (!orgaosPorCnpj.TryGetValue(cnpjOrgao, out var idOrgao))
            {
                idOrgao = await GarantirOrgaoAsync(
                    conexao, transacao, cnpjOrgao, dados.Orgao!.RazaoSocial!, dados.Orgao!.EsferaId, cancellationToken);
                orgaosPorCnpj[cnpjOrgao] = idOrgao;
            }

            const string sql = @"
                INSERT INTO tb_licitacoes
                    (nr_controle_pncp, id_orgao, nr_edital, cd_modalidade, nm_modalidade, nm_modo_disputa,
                     st_situacao, ds_objeto, vl_estimado, sg_uf, nm_municipio, dh_publicacao,
                     dh_inicio_propostas, dh_fim_propostas, ds_link_origem, js_payload, dh_sincronizacao)
                VALUES
                    (@NrControlePncp, @IdOrgao, @NrEdital, @CdModalidade, @NmModalidade, @NmModoDisputa,
                     @StSituacao, @DsObjeto, @VlEstimado, @SgUf, @NmMunicipio, @DhPublicacao,
                     @DhInicioPropostas, @DhFimPropostas, @DsLinkOrigem, @JsPayload, @DhSincronizacao)
                ON DUPLICATE KEY UPDATE
                    id_orgao = VALUES(id_orgao),
                    nr_edital = VALUES(nr_edital),
                    cd_modalidade = VALUES(cd_modalidade),
                    nm_modalidade = VALUES(nm_modalidade),
                    nm_modo_disputa = VALUES(nm_modo_disputa),
                    st_situacao = VALUES(st_situacao),
                    ds_objeto = VALUES(ds_objeto),
                    vl_estimado = VALUES(vl_estimado),
                    sg_uf = VALUES(sg_uf),
                    nm_municipio = VALUES(nm_municipio),
                    dh_publicacao = VALUES(dh_publicacao),
                    dh_inicio_propostas = VALUES(dh_inicio_propostas),
                    dh_fim_propostas = VALUES(dh_fim_propostas),
                    ds_link_origem = VALUES(ds_link_origem),
                    js_payload = VALUES(js_payload),
                    dh_sincronizacao = VALUES(dh_sincronizacao);";

            using var comando = new MySqlCommand(sql, conexao, transacao);
            comando.Parameters.AddWithValue("@NrControlePncp", dados.NumeroControlePncp);
            comando.Parameters.AddWithValue("@IdOrgao", idOrgao);
            comando.Parameters.AddWithValue("@NrEdital", (object?)dados.NumeroEdital ?? DBNull.Value);
            comando.Parameters.AddWithValue("@CdModalidade", dados.ModalidadeId!.Value);
            comando.Parameters.AddWithValue("@NmModalidade", dados.ModalidadeNome);
            comando.Parameters.AddWithValue("@NmModoDisputa", (object?)dados.ModoDisputaNome ?? DBNull.Value);
            comando.Parameters.AddWithValue("@StSituacao", dados.SituacaoNome);
            comando.Parameters.AddWithValue("@DsObjeto", dados.Objeto);
            comando.Parameters.AddWithValue("@VlEstimado", (object?)dados.ValorEstimado ?? DBNull.Value);
            comando.Parameters.AddWithValue("@SgUf", (object?)NormalizarUf(dados.Unidade?.UfSigla) ?? DBNull.Value);
            comando.Parameters.AddWithValue("@NmMunicipio", (object?)dados.Unidade?.MunicipioNome ?? DBNull.Value);
            comando.Parameters.AddWithValue("@DhPublicacao",
                (object?)PncpService.HorarioBrasiliaParaUtc(dados.DataPublicacao) ?? DBNull.Value);
            comando.Parameters.AddWithValue("@DhInicioPropostas",
                (object?)PncpService.HorarioBrasiliaParaUtc(dados.DataAberturaProposta) ?? DBNull.Value);
            comando.Parameters.AddWithValue("@DhFimPropostas",
                (object?)PncpService.HorarioBrasiliaParaUtc(dados.DataEncerramentoProposta) ?? DBNull.Value);
            comando.Parameters.AddWithValue("@DsLinkOrigem", (object?)dados.LinkOrigem ?? DBNull.Value);
            comando.Parameters.AddWithValue("@JsPayload", contratacao.PayloadBruto);
            comando.Parameters.AddWithValue("@DhSincronizacao", DateTime.UtcNow);

            await comando.ExecuteNonQueryAsync(cancellationToken);
            gravados++;
        }

        await transacao.CommitAsync(cancellationToken);
        return new ResultadoGravacao(gravados, descartados);
    }

    public async Task<MetricasDashboard> ObterMetricasDashboardAsync()
    {
        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();

        using var comandoAtivas = new MySqlCommand(
            @"SELECT COUNT(*)
              FROM tb_licitacoes
              WHERE dh_fim_propostas IS NOT NULL
                AND dh_fim_propostas >= UTC_TIMESTAMP()", conexao);
        var ativas = Convert.ToInt32(await comandoAtivas.ExecuteScalarAsync());

        using var comandoGanhas = new MySqlCommand(
            @"SELECT COALESCE(SUM(l.vl_estimado), 0)
              FROM tb_acompanhamentos a
              INNER JOIN tb_licitacoes l ON l.id_licitacao = a.id_licitacao
              WHERE a.st_acompanhamento = 'GANHOU'", conexao);
        var totalGanho = Convert.ToDecimal(await comandoGanhas.ExecuteScalarAsync());

        using var comandoUltimo = new MySqlCommand(
            @"SELECT o.nm_razao_social
              FROM tb_licitacoes l
              INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
              ORDER BY l.dh_publicacao IS NULL, l.dh_publicacao DESC, l.id_licitacao DESC
              LIMIT 1", conexao);
        var ultimoOrgao = (await comandoUltimo.ExecuteScalarAsync())?.ToString() ?? string.Empty;

        return new MetricasDashboard(ativas, totalGanho, ultimoOrgao);
    }

    private static async Task<long> GarantirOrgaoAsync(
        MySqlConnection conexao, MySqlTransaction transacao,
        string cnpj, string razaoSocial, string? esferaId, CancellationToken cancellationToken)
    {
        const string sqlUpsert = @"
            INSERT INTO tb_orgaos (nr_cnpj, nm_razao_social, tp_esfera)
            VALUES (@NrCnpj, @NmRazaoSocial, @TpEsfera)
            ON DUPLICATE KEY UPDATE
                nm_razao_social = VALUES(nm_razao_social),
                tp_esfera = COALESCE(VALUES(tp_esfera), tp_esfera);";

        using (var comandoUpsert = new MySqlCommand(sqlUpsert, conexao, transacao))
        {
            comandoUpsert.Parameters.AddWithValue("@NrCnpj", cnpj);
            comandoUpsert.Parameters.AddWithValue("@NmRazaoSocial", razaoSocial);
            comandoUpsert.Parameters.AddWithValue("@TpEsfera", (object?)ConverterEsfera(esferaId) ?? DBNull.Value);
            await comandoUpsert.ExecuteNonQueryAsync(cancellationToken);
        }

        using var comandoId = new MySqlCommand(
            "SELECT id_orgao FROM tb_orgaos WHERE nr_cnpj = @NrCnpj", conexao, transacao);
        comandoId.Parameters.AddWithValue("@NrCnpj", cnpj);
        return Convert.ToInt64(await comandoId.ExecuteScalarAsync(cancellationToken));
    }

    private static string SomenteAlfanumericos(string? texto)
        => texto is null ? string.Empty : new string(texto.Where(char.IsLetterOrDigit).ToArray());

    private static string? NormalizarUf(string? uf)
    {
        if (string.IsNullOrWhiteSpace(uf))
        {
            return null;
        }

        var normalizada = uf.Trim().ToUpperInvariant();
        return UfsValidas.Contains(normalizada) ? normalizada : null;
    }

    private static string? ConverterEsfera(string? esferaId) => esferaId?.Trim().ToUpperInvariant() switch
    {
        "F" => "FEDERAL",
        "E" => "ESTADUAL",
        "M" => "MUNICIPAL",
        "D" => "DISTRITAL",
        null or "" => null,
        _ => "OUTRA"
    };
}

public record ResultadoGravacao(int Gravados, int Descartados);

public record MetricasDashboard(int Ativas, decimal TotalGanho, string UltimoOrgao);

using MySqlConnector;

namespace licithub_api_empresas.Services;

public class EditalRepository
{
    private static readonly HashSet<string> UfsValidas = new(StringComparer.OrdinalIgnoreCase)
    {
        "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG",
        "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
    };

    private static readonly HashSet<string> StatusAcompanhamentoValidos = new(StringComparer.OrdinalIgnoreCase)
    {
        "INTERESSE", "ANALISANDO", "PROPOSTA_EM_PREPARO", "PARTICIPANDO", "GANHOU", "PERDEU", "DESCARTADO"
    };

    private readonly string _connectionString;

    public EditalRepository(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("ConnectionStrings:DefaultConnection não configurada.");

        _connectionString = connectionString;
    }

    public async Task<long> IniciarExecucaoSyncAsync(CancellationToken ct)
    {
        using var conn = new MySqlConnection(_connectionString);
        await conn.OpenAsync(ct);

        using var cmd = new MySqlCommand(@"
            INSERT INTO tb_execucoes_sincronizacao (dh_inicio, st_execucao, dh_janela_inicio, dh_janela_fim)
            VALUES (UTC_TIMESTAMP(), 'EXECUTANDO', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 7 DAY), DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY));
            SELECT LAST_INSERT_ID();", conn);

        return Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));
    }

    public async Task FinalizarExecucaoSyncAsync(
        long idExecucao, string status, int lidos, int gravados, string? erro, CancellationToken ct)
    {
        using var conn = new MySqlConnection(_connectionString);
        await conn.OpenAsync(ct);

        using var cmd = new MySqlCommand(@"
            UPDATE tb_execucoes_sincronizacao
            SET dh_fim = UTC_TIMESTAMP(),
                st_execucao = @Status,
                qt_registros_lidos = @Lidos,
                qt_registros_novos = @Gravados,
                ds_erro = @Erro
            WHERE id_execucao_sincronizacao = @Id;", conn);

        cmd.Parameters.AddWithValue("@Status", status);
        cmd.Parameters.AddWithValue("@Lidos", lidos);
        cmd.Parameters.AddWithValue("@Gravados", gravados);
        cmd.Parameters.AddWithValue("@Erro", (object?)erro ?? DBNull.Value);
        cmd.Parameters.AddWithValue("@Id", idExecucao);
        await cmd.ExecuteNonQueryAsync(ct);
    }

    public async Task<ResultadoGravacao> SalvarEditaisAsync(List<ContratacaoPncp> contratacoes, CancellationToken cancellationToken)
    {
        var gravados = 0;
        var descartados = 0;

        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync(cancellationToken);

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

            try
            {
                if (!orgaosPorCnpj.TryGetValue(cnpjOrgao, out var idOrgao))
                {
                    idOrgao = await GarantirOrgaoAsync(
                        conexao, cnpjOrgao, Truncar(dados.Orgao!.RazaoSocial!, 255)!, dados.Orgao!.EsferaId, cancellationToken);
                    orgaosPorCnpj[cnpjOrgao] = idOrgao;
                }

                var dhPub = PncpService.HorarioBrasiliaParaUtc(dados.DataPublicacao);
                var dhInicio = PncpService.HorarioBrasiliaParaUtc(dados.DataAberturaProposta);
                var dhFim = PncpService.HorarioBrasiliaParaUtc(dados.DataEncerramentoProposta);

                if (dhInicio.HasValue && dhFim.HasValue && dhFim.Value < dhInicio.Value)
                {
                    dhInicio = null;
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

                using var comando = new MySqlCommand(sql, conexao);
                comando.Parameters.AddWithValue("@NrControlePncp", Truncar(dados.NumeroControlePncp, 60));
                comando.Parameters.AddWithValue("@IdOrgao", idOrgao);
                comando.Parameters.AddWithValue("@NrEdital", (object?)Truncar(dados.NumeroEdital, 80) ?? DBNull.Value);
                comando.Parameters.AddWithValue("@CdModalidade", dados.ModalidadeId!.Value);
                comando.Parameters.AddWithValue("@NmModalidade", Truncar(dados.ModalidadeNome, 80));
                comando.Parameters.AddWithValue("@NmModoDisputa", (object?)Truncar(dados.ModoDisputaNome, 40) ?? DBNull.Value);
                comando.Parameters.AddWithValue("@StSituacao", Truncar(dados.SituacaoNome, 40));
                comando.Parameters.AddWithValue("@DsObjeto", dados.Objeto);
                comando.Parameters.AddWithValue("@VlEstimado", (object?)dados.ValorEstimado ?? DBNull.Value);
                comando.Parameters.AddWithValue("@SgUf", (object?)NormalizarUf(dados.Unidade?.UfSigla) ?? DBNull.Value);
                comando.Parameters.AddWithValue("@NmMunicipio", (object?)Truncar(dados.Unidade?.MunicipioNome, 100) ?? DBNull.Value);
                comando.Parameters.AddWithValue("@DhPublicacao", (object?)dhPub ?? DBNull.Value);
                comando.Parameters.AddWithValue("@DhInicioPropostas", (object?)dhInicio ?? DBNull.Value);
                comando.Parameters.AddWithValue("@DhFimPropostas", (object?)dhFim ?? DBNull.Value);
                comando.Parameters.AddWithValue("@DsLinkOrigem", (object?)Truncar(dados.LinkOrigem, 500) ?? DBNull.Value);
                comando.Parameters.AddWithValue("@JsPayload", contratacao.PayloadBruto);
                comando.Parameters.AddWithValue("@DhSincronizacao", DateTime.UtcNow);

                await comando.ExecuteNonQueryAsync(cancellationToken);
                gravados++;
            }
            catch
            {
                descartados++;
            }
        }

        return new ResultadoGravacao(gravados, descartados);
    }

    public async Task<DashboardCompletoDto> ObterDashboardCompletoAsync(long? idEmpresa)
    {
        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();

        using var cmdAtivas = new MySqlCommand(
            @"SELECT COUNT(*) FROM tb_licitacoes
              WHERE dh_fim_propostas IS NULL OR dh_fim_propostas >= UTC_TIMESTAMP()", conexao);
        var ativas = Convert.ToInt32(await cmdAtivas.ExecuteScalarAsync());

        decimal totalGanho = 0;
        if (idEmpresa.HasValue && idEmpresa.Value > 0)
        {
            using var cmdGanhas = new MySqlCommand(
                @"SELECT COALESCE(SUM(l.vl_estimado), 0)
                  FROM tb_acompanhamentos a
                  INNER JOIN tb_licitacoes l ON l.id_licitacao = a.id_licitacao
                  WHERE a.id_empresa = @IdEmpresa AND a.st_acompanhamento = 'GANHOU'", conexao);
            cmdGanhas.Parameters.AddWithValue("@IdEmpresa", idEmpresa.Value);
            totalGanho = Convert.ToDecimal(await cmdGanhas.ExecuteScalarAsync());
        }

        using var cmdUltimo = new MySqlCommand(
            @"SELECT o.nm_razao_social FROM tb_licitacoes l
              INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
              ORDER BY l.dh_publicacao IS NULL, l.dh_publicacao DESC, l.id_licitacao DESC LIMIT 1", conexao);
        var ultimoOrgao = (await cmdUltimo.ExecuteScalarAsync())?.ToString() ?? string.Empty;

        // Volume por UF (top 7 estados com mais editais reais no banco)
        var volumePorUf = new List<PontoGraficoDto>();
        using (var cmdGrafico = new MySqlCommand(
            @"SELECT COALESCE(sg_uf, 'BR') AS label, COUNT(*) AS qtd
              FROM tb_licitacoes
              GROUP BY COALESCE(sg_uf, 'BR')
              ORDER BY qtd DESC LIMIT 7", conexao))
        using (var reader = await cmdGrafico.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                volumePorUf.Add(new PontoGraficoDto(
                    reader.GetString("label"),
                    reader.GetInt32("qtd")));
            }
        }

        // Últimas 5 oportunidades reais gravadas no banco
        var recentes = new List<LicitacaoResumoDto>();
        using (var cmdRecentes = new MySqlCommand(
            @"SELECT l.id_licitacao, l.nr_controle_pncp, l.nr_edital, l.nm_modalidade, l.st_situacao,
                     l.ds_objeto, l.vl_estimado, l.sg_uf, l.nm_municipio, l.dh_fim_propostas, l.ds_link_origem,
                     o.nm_razao_social, o.nr_cnpj
              FROM tb_licitacoes l
              INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
              ORDER BY l.dh_publicacao IS NULL, l.dh_publicacao DESC, l.id_licitacao DESC
              LIMIT 5", conexao))
        using (var reader = await cmdRecentes.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                recentes.Add(LerLicitacaoResumo(reader));
            }
        }

        var alerta = string.IsNullOrEmpty(ultimoOrgao)
            ? "Nenhuma licitação encontrada no banco. Clique em 'Sincronizar PNCP' para importar editais reais."
            : $"Publicação mais recente importada do PNCP: {ultimoOrgao}";

        return new DashboardCompletoDto(ativas, totalGanho, alerta, volumePorUf, recentes);
    }

    public async Task<ResultadoBuscaLicitacoesDto> BuscarLicitacoesAsync(
        string? termo, string? uf, decimal? valorMinimo, string? modalidade, string? situacao, string? municipio, int pagina, int tamanhoPagina)
    {
        pagina = Math.Max(1, pagina);
        tamanhoPagina = Math.Clamp(tamanhoPagina, 5, 50);
        var offset = (pagina - 1) * tamanhoPagina;

        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();

        var filtros = new List<string>();
        var parametros = new List<MySqlParameter>();

        if (!string.IsNullOrWhiteSpace(termo))
        {
            filtros.Add("(l.ds_objeto LIKE @Termo OR o.nm_razao_social LIKE @Termo OR l.nm_municipio LIKE @Termo)");
            parametros.Add(new MySqlParameter("@Termo", $"%{termo.Trim()}%"));
        }

        if (!string.IsNullOrWhiteSpace(uf) && UfsValidas.Contains(uf.Trim()))
        {
            filtros.Add("l.sg_uf = @Uf");
            parametros.Add(new MySqlParameter("@Uf", uf.Trim().ToUpperInvariant()));
        }

        if (valorMinimo.HasValue && valorMinimo.Value > 0)
        {
            filtros.Add("l.vl_estimado >= @ValorMin");
            parametros.Add(new MySqlParameter("@ValorMin", valorMinimo.Value));
        }

        if (!string.IsNullOrWhiteSpace(modalidade))
        {
            filtros.Add("l.nm_modalidade LIKE @Modalidade");
            parametros.Add(new MySqlParameter("@Modalidade", $"%{modalidade.Trim()}%"));
        }

        if (!string.IsNullOrWhiteSpace(situacao))
        {
            filtros.Add("l.st_situacao LIKE @Situacao");
            parametros.Add(new MySqlParameter("@Situacao", $"%{situacao.Trim()}%"));
        }

        if (!string.IsNullOrWhiteSpace(municipio))
        {
            filtros.Add("l.nm_municipio LIKE @Municipio");
            parametros.Add(new MySqlParameter("@Municipio", $"%{municipio.Trim()}%"));
        }

        var where = filtros.Count > 0 ? "WHERE " + string.Join(" AND ", filtros) : "";

        using var cmdCount = new MySqlCommand(
            $"SELECT COUNT(*) FROM tb_licitacoes l INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao {where}", conexao);
        foreach (var p in parametros) cmdCount.Parameters.Add(new MySqlParameter(p.ParameterName, p.Value));
        var total = Convert.ToInt32(await cmdCount.ExecuteScalarAsync());

        var itens = new List<LicitacaoResumoDto>();
        using var cmdLista = new MySqlCommand($@"
            SELECT l.id_licitacao, l.nr_controle_pncp, l.nr_edital, l.nm_modalidade, l.st_situacao,
                   l.ds_objeto, l.vl_estimado, l.sg_uf, l.nm_municipio, l.dh_fim_propostas, l.ds_link_origem,
                   o.nm_razao_social, o.nr_cnpj
            FROM tb_licitacoes l
            INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
            {where}
            ORDER BY l.dh_publicacao IS NULL, l.dh_publicacao DESC, l.id_licitacao DESC
            LIMIT @Limit OFFSET @Offset", conexao);

        foreach (var p in parametros) cmdLista.Parameters.Add(new MySqlParameter(p.ParameterName, p.Value));
        cmdLista.Parameters.AddWithValue("@Limit", tamanhoPagina);
        cmdLista.Parameters.AddWithValue("@Offset", offset);

        using var reader = await cmdLista.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            itens.Add(LerLicitacaoResumo(reader));
        }

        return new ResultadoBuscaLicitacoesDto(total, pagina, tamanhoPagina, itens);
    }

    public async Task<LicitacaoDetalheDto?> ObterLicitacaoDetalheAsync(
        long idLicitacao, PncpService pncpService, CancellationToken ct)
    {
        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync(ct);

        LicitacaoResumoDto? resumo = null;
        using (var cmd = new MySqlCommand(@"
            SELECT l.id_licitacao, l.nr_controle_pncp, l.nr_edital, l.nm_modalidade, l.st_situacao,
                   l.ds_objeto, l.vl_estimado, l.sg_uf, l.nm_municipio, l.dh_fim_propostas, l.ds_link_origem,
                   o.nm_razao_social, o.nr_cnpj
            FROM tb_licitacoes l
            INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
            WHERE l.id_licitacao = @Id", conexao))
        {
            cmd.Parameters.AddWithValue("@Id", idLicitacao);
            using var reader = await cmd.ExecuteReaderAsync(ct);
            if (await reader.ReadAsync(ct))
                resumo = LerLicitacaoResumo(reader);
        }

        if (resumo is null)
            return null;

        var itens = await LerItensBancoAsync(conexao, idLicitacao, ct);
        if (itens.Count == 0)
        {
            var itensPncp = await pncpService.ObterItensContratacaoAsync(resumo.NumeroControlePncp, ct);
            if (itensPncp.Count > 0)
            {
                await SalvarItensLicitacaoAsync(conexao, idLicitacao, itensPncp, ct);
                itens = await LerItensBancoAsync(conexao, idLicitacao, ct);
            }
        }

        return new LicitacaoDetalheDto(resumo, itens);
    }

    public async Task<List<AcompanhamentoItemDto>> ListarAcompanhamentosAsync(long idEmpresa)
    {
        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();

        var lista = new List<AcompanhamentoItemDto>();
        using var cmd = new MySqlCommand(@"
            SELECT a.id_acompanhamento, a.id_licitacao, a.st_acompanhamento, a.ds_anotacoes,
                   l.nr_controle_pncp, l.nr_edital, l.nm_modalidade, l.ds_objeto, l.vl_estimado, l.sg_uf,
                   o.nm_razao_social
            FROM tb_acompanhamentos a
            INNER JOIN tb_licitacoes l ON l.id_licitacao = a.id_licitacao
            INNER JOIN tb_orgaos o ON o.id_orgao = l.id_orgao
            WHERE a.id_empresa = @IdEmpresa
            ORDER BY a.dh_atualizacao DESC", conexao);

        cmd.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            lista.Add(new AcompanhamentoItemDto(
                reader.GetInt64("id_acompanhamento"),
                reader.GetInt64("id_licitacao"),
                reader.GetString("st_acompanhamento"),
                reader.IsDBNull(reader.GetOrdinal("ds_anotacoes")) ? null : reader.GetString("ds_anotacoes"),
                reader.GetString("nr_controle_pncp"),
                reader.IsDBNull(reader.GetOrdinal("nr_edital")) ? "S/N" : reader.GetString("nr_edital"),
                reader.GetString("nm_modalidade"),
                reader.GetString("nm_razao_social"),
                reader.GetString("ds_objeto"),
                reader.IsDBNull(reader.GetOrdinal("vl_estimado")) ? 0m : reader.GetDecimal("vl_estimado"),
                reader.IsDBNull(reader.GetOrdinal("sg_uf")) ? "" : reader.GetString("sg_uf")
            ));
        }

        return lista;
    }

    public async Task<long> AdicionarAcompanhamentoAsync(long idEmpresa, long idUsuario, long idLicitacao, string? anotacoes)
    {
        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();
        using var tx = await conexao.BeginTransactionAsync();

        using var cmd = new MySqlCommand(@"
            INSERT INTO tb_acompanhamentos (id_empresa, id_licitacao, id_usuario_criacao, st_acompanhamento, ds_anotacoes)
            VALUES (@IdEmpresa, @IdLicitacao, @IdUsuario, 'INTERESSE', @Anotacoes)
            ON DUPLICATE KEY UPDATE dh_atualizacao = CURRENT_TIMESTAMP;
            SELECT id_acompanhamento FROM tb_acompanhamentos WHERE id_empresa = @IdEmpresa AND id_licitacao = @IdLicitacao;", conexao, tx);

        cmd.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        cmd.Parameters.AddWithValue("@IdLicitacao", idLicitacao);
        cmd.Parameters.AddWithValue("@IdUsuario", idUsuario);
        cmd.Parameters.AddWithValue("@Anotacoes", (object?)anotacoes ?? DBNull.Value);

        var idAcomp = Convert.ToInt64(await cmd.ExecuteScalarAsync());

        using var cmdEv = new MySqlCommand(@"
            INSERT INTO tb_acompanhamentos_eventos (id_acompanhamento, id_usuario, st_anterior, st_novo, ds_observacao)
            VALUES (@IdAcomp, @IdUsuario, NULL, 'INTERESSE', 'Licitação adicionada ao funil');", conexao, tx);
        cmdEv.Parameters.AddWithValue("@IdAcomp", idAcomp);
        cmdEv.Parameters.AddWithValue("@IdUsuario", idUsuario);
        await cmdEv.ExecuteNonQueryAsync();

        await tx.CommitAsync();
        return idAcomp;
    }

    public async Task<bool> AtualizarStatusAcompanhamentoAsync(
        long idEmpresa, long idUsuario, long idAcompanhamento, string novoStatus, string? observacao)
    {
        var statusNorm = novoStatus.Trim().ToUpperInvariant();
        if (!StatusAcompanhamentoValidos.Contains(statusNorm))
            throw new ArgumentException($"Status inválido: {novoStatus}");

        using var conexao = new MySqlConnection(_connectionString);
        await conexao.OpenAsync();
        using var tx = await conexao.BeginTransactionAsync();

        using var cmdAtual = new MySqlCommand(
            "SELECT st_acompanhamento FROM tb_acompanhamentos WHERE id_acompanhamento = @Id AND id_empresa = @IdEmpresa",
            conexao, tx);
        cmdAtual.Parameters.AddWithValue("@Id", idAcompanhamento);
        cmdAtual.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        var statusAnterior = (await cmdAtual.ExecuteScalarAsync())?.ToString();

        if (statusAnterior is null)
            return false;

        using var cmdUpd = new MySqlCommand(@"
            UPDATE tb_acompanhamentos
            SET st_acompanhamento = @NovoStatus,
                ds_anotacoes = COALESCE(@Obs, ds_anotacoes)
            WHERE id_acompanhamento = @Id AND id_empresa = @IdEmpresa", conexao, tx);
        cmdUpd.Parameters.AddWithValue("@NovoStatus", statusNorm);
        cmdUpd.Parameters.AddWithValue("@Obs", (object?)observacao ?? DBNull.Value);
        cmdUpd.Parameters.AddWithValue("@Id", idAcompanhamento);
        cmdUpd.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        await cmdUpd.ExecuteNonQueryAsync();

        using var cmdEv = new MySqlCommand(@"
            INSERT INTO tb_acompanhamentos_eventos (id_acompanhamento, id_usuario, st_anterior, st_novo, ds_observacao)
            VALUES (@Id, @IdUsuario, @Anterior, @Novo, @Obs)", conexao, tx);
        cmdEv.Parameters.AddWithValue("@Id", idAcompanhamento);
        cmdEv.Parameters.AddWithValue("@IdUsuario", idUsuario);
        cmdEv.Parameters.AddWithValue("@Anterior", statusAnterior);
        cmdEv.Parameters.AddWithValue("@Novo", statusNorm);
        cmdEv.Parameters.AddWithValue("@Obs", (object?)Truncar(observacao, 500) ?? DBNull.Value);
        await cmdEv.ExecuteNonQueryAsync();

        await tx.CommitAsync();
        return true;
    }

    private static async Task<List<ItemLicitacaoDetalheDto>> LerItensBancoAsync(
        MySqlConnection conexao, long idLicitacao, CancellationToken ct)
    {
        var lista = new List<ItemLicitacaoDetalheDto>();
        using var cmd = new MySqlCommand(@"
            SELECT nr_item, ds_item, qt_item, nm_unidade, vl_unitario_estimado, ds_tratamento_diferenciado
            FROM tb_licitacoes_itens
            WHERE id_licitacao = @Id
            ORDER BY nr_item ASC", conexao);
        cmd.Parameters.AddWithValue("@Id", idLicitacao);

        using var reader = await cmd.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct))
        {
            lista.Add(new ItemLicitacaoDetalheDto(
                reader.GetInt32("nr_item"),
                reader.GetString("ds_item"),
                reader.IsDBNull(reader.GetOrdinal("qt_item")) ? 0m : reader.GetDecimal("qt_item"),
                reader.IsDBNull(reader.GetOrdinal("nm_unidade")) ? "UN" : reader.GetString("nm_unidade"),
                reader.IsDBNull(reader.GetOrdinal("vl_unitario_estimado")) ? 0m : reader.GetDecimal("vl_unitario_estimado"),
                reader.IsDBNull(reader.GetOrdinal("ds_tratamento_diferenciado")) ? null : reader.GetString("ds_tratamento_diferenciado")
            ));
        }

        return lista;
    }

    private static async Task SalvarItensLicitacaoAsync(
        MySqlConnection conexao, long idLicitacao, List<ItemLicitacaoPncpDto> itens, CancellationToken ct)
    {
        foreach (var item in itens.Where(i => i.NumeroItem > 0 && !string.IsNullOrWhiteSpace(i.Descricao)))
        {
            using var cmd = new MySqlCommand(@"
                INSERT INTO tb_licitacoes_itens
                    (id_licitacao, nr_item, ds_item, qt_item, nm_unidade, vl_unitario_estimado, ds_tratamento_diferenciado)
                VALUES
                    (@IdLicitacao, @NrItem, @DsItem, @QtItem, @NmUnidade, @VlUnitario, @Beneficio)
                ON DUPLICATE KEY UPDATE
                    ds_item = VALUES(ds_item),
                    qt_item = VALUES(qt_item),
                    vl_unitario_estimado = VALUES(vl_unitario_estimado);", conexao);

            cmd.Parameters.AddWithValue("@IdLicitacao", idLicitacao);
            cmd.Parameters.AddWithValue("@NrItem", item.NumeroItem);
            cmd.Parameters.AddWithValue("@DsItem", item.Descricao!.Trim());
            cmd.Parameters.AddWithValue("@QtItem", (object?)item.Quantidade ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@NmUnidade", (object?)Truncar(item.UnidadeMedida, 30) ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@VlUnitario", (object?)item.ValorUnitarioEstimado ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@Beneficio", (object?)Truncar(item.TipoBeneficioNome, 60) ?? DBNull.Value);
            await cmd.ExecuteNonQueryAsync(ct);
        }
    }

    private static LicitacaoResumoDto LerLicitacaoResumo(MySqlDataReader reader)
    {
        var nrControle = reader.GetString("nr_controle_pncp");
        var linkOrigem = reader.IsDBNull(reader.GetOrdinal("ds_link_origem"))
            ? null
            : reader.GetString("ds_link_origem");

        if (string.IsNullOrWhiteSpace(linkOrigem))
        {
            var partes = nrControle.Split('/');
            var tracos = partes[0].Split('-');
            if (partes.Length == 2 && tracos.Length >= 3)
                linkOrigem = $"https://pncp.gov.br/app/editais/{tracos[0]}/{partes[1]}/{int.Parse(tracos[2])}";
        }

        return new LicitacaoResumoDto(
            reader.GetInt64("id_licitacao"),
            nrControle,
            reader.IsDBNull(reader.GetOrdinal("nr_edital")) ? "S/N" : reader.GetString("nr_edital"),
            reader.GetString("nm_modalidade"),
            reader.GetString("st_situacao"),
            reader.GetString("nm_razao_social"),
            reader.GetString("nr_cnpj"),
            reader.GetString("ds_objeto"),
            reader.IsDBNull(reader.GetOrdinal("vl_estimado")) ? 0m : reader.GetDecimal("vl_estimado"),
            reader.IsDBNull(reader.GetOrdinal("sg_uf")) ? "" : reader.GetString("sg_uf"),
            reader.IsDBNull(reader.GetOrdinal("nm_municipio")) ? "" : reader.GetString("nm_municipio"),
            reader.IsDBNull(reader.GetOrdinal("dh_fim_propostas")) ? null : reader.GetDateTime("dh_fim_propostas"),
            linkOrigem
        );
    }

    private static async Task<long> GarantirOrgaoAsync(
        MySqlConnection conexao, string cnpj, string razaoSocial, string? esferaId, CancellationToken cancellationToken)
    {
        const string sqlUpsert = @"
            INSERT INTO tb_orgaos (nr_cnpj, nm_razao_social, tp_esfera)
            VALUES (@NrCnpj, @NmRazaoSocial, @TpEsfera)
            ON DUPLICATE KEY UPDATE
                nm_razao_social = VALUES(nm_razao_social),
                tp_esfera = COALESCE(VALUES(tp_esfera), tp_esfera);";

        using (var comandoUpsert = new MySqlCommand(sqlUpsert, conexao))
        {
            comandoUpsert.Parameters.AddWithValue("@NrCnpj", cnpj);
            comandoUpsert.Parameters.AddWithValue("@NmRazaoSocial", razaoSocial);
            comandoUpsert.Parameters.AddWithValue("@TpEsfera", (object?)ConverterEsfera(esferaId) ?? DBNull.Value);
            await comandoUpsert.ExecuteNonQueryAsync(cancellationToken);
        }

        using var comandoId = new MySqlCommand("SELECT id_orgao FROM tb_orgaos WHERE nr_cnpj = @NrCnpj", conexao);
        comandoId.Parameters.AddWithValue("@NrCnpj", cnpj);
        return Convert.ToInt64(await comandoId.ExecuteScalarAsync(cancellationToken));
    }

    private static string? Truncar(string? valor, int max)
        => string.IsNullOrWhiteSpace(valor) ? null : (valor.Trim().Length <= max ? valor.Trim() : valor.Trim()[..max]);

    private static string SomenteAlfanumericos(string? texto)
        => texto is null ? string.Empty : new string(texto.Where(char.IsLetterOrDigit).ToArray());

    private static string? NormalizarUf(string? uf)
    {
        if (string.IsNullOrWhiteSpace(uf)) return null;
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
public record PontoGraficoDto(string Label, int Quantidade);
public record DashboardCompletoDto(
    int LicitacoesAtivas,
    decimal DisputasGanhas,
    string Alerta,
    List<PontoGraficoDto> VolumePorUf,
    List<LicitacaoResumoDto> UltimasOportunidades);
public record LicitacaoResumoDto(
    long Id,
    string NumeroControlePncp,
    string NumeroEdital,
    string Modalidade,
    string Situacao,
    string Orgao,
    string CnpjOrgao,
    string Objeto,
    decimal ValorEstimado,
    string Uf,
    string Municipio,
    DateTime? DataEncerramentoProposta,
    string? LinkOrigem);
public record ResultadoBuscaLicitacoesDto(
    int Total,
    int Pagina,
    int TamanhoPagina,
    List<LicitacaoResumoDto> Itens);
public record ItemLicitacaoDetalheDto(
    int NumeroItem,
    string Descricao,
    decimal Quantidade,
    string Unidade,
    decimal ValorUnitarioEstimado,
    string? BeneficioMeEpp);
public record LicitacaoDetalheDto(
    LicitacaoResumoDto Edital,
    List<ItemLicitacaoDetalheDto> Itens);
public record AcompanhamentoItemDto(
    long IdAcompanhamento,
    long IdLicitacao,
    string Status,
    string? Anotacoes,
    string NumeroControlePncp,
    string NumeroEdital,
    string Modalidade,
    string Orgao,
    string Objeto,
    decimal ValorEstimado,
    string Uf);
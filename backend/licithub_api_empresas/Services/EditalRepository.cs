using MySqlConnector;

namespace licithub_api_empresas.Services;

public class EditalRepository
{
    private readonly string _connectionString;

    public EditalRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection") 
            ?? "Server=localhost;Database=licithub_db;User=root;Password=;";
    }

    public async Task SalvarEditaisAsync(List<EditalPncpDto> editais)
    {
        try
        {
            using var connection = new MySqlConnection(_connectionString);
            await connection.OpenAsync();

            int inseridos = 0;
            foreach (var edital in editais)
            {
                var query = @"
                    INSERT INTO licitacoes (numero_contratacao, orgao_nome, objeto, valor_estimado, status_kanban)
                    VALUES (@Numero, @Orgao, @Objeto, @Valor, 'Mapeados')
                    ON DUPLICATE KEY UPDATE 
                        orgao_nome = VALUES(orgao_nome),
                        objeto = VALUES(objeto),
                        valor_estimado = VALUES(valor_estimado);";

                using var cmd = new MySqlCommand(query, connection);
                cmd.Parameters.AddWithValue("@Numero", edital.CodigoIdentificador);
                cmd.Parameters.AddWithValue("@Orgao", edital.Orgao?.Nome ?? "Órgão Público");
                cmd.Parameters.AddWithValue("@Objeto", edital.Objeto ?? "Sem descrição de objeto");
                cmd.Parameters.AddWithValue("@Valor", edital.ValorEstimado ?? 0);

                await cmd.ExecuteNonQueryAsync();
                inseridos++;
            }

            Console.WriteLine($"[MYSQL SUCESSO] {inseridos} editais guardados na base de dados.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[MYSQL ERRO] Falha ao guardar na base de dados: {ex.Message}");
        }
    }

    public async Task<(int ativas, decimal totalGanho, string ultimoOrgao)> ObterMetricasDashboardAsync()
    {
        using var connection = new MySqlConnection(_connectionString);
        await connection.OpenAsync();

        using var cmdAtivas = new MySqlCommand("SELECT COUNT(*) FROM licitacoes", connection);
        var ativas = Convert.ToInt32(await cmdAtivas.ExecuteScalarAsync());

        using var cmdGanhas = new MySqlCommand("SELECT COALESCE(SUM(valor_estimado), 0) FROM licitacoes WHERE status_kanban = 'Ganho'", connection);
        var totalGanho = Convert.ToDecimal(await cmdGanhas.ExecuteScalarAsync());

        using var cmdUltimo = new MySqlCommand("SELECT orgao_nome FROM licitacoes ORDER BY id DESC LIMIT 1", connection);
        var ultimoOrgaoObj = await cmdUltimo.ExecuteScalarAsync();
        var ultimoOrgao = ultimoOrgaoObj != null ? ultimoOrgaoObj.ToString()! : string.Empty;

        return (ativas, totalGanho, ultimoOrgao);
    }
}
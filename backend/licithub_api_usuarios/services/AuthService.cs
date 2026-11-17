using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using licithub_api_usuarios.Configuration;
using licithub_api_usuarios.Data;
using licithub_api_usuarios.Dtos;
using licithub_api_usuarios.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using MySqlConnector;
using Microsoft.EntityFrameworkCore.Storage;

namespace licithub_api_usuarios.Services;

public interface IAuthService
{
    Task<UsuarioResponse> RegistrarAsync(RegistrarUsuarioRequest request, CancellationToken cancellationToken);
    Task<TokenResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
    Task<TokenResponse?> RenovarTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken);
    Task<UsuarioResponse?> ObterAsync(long usuarioId, CancellationToken cancellationToken);
    Task RevogarTokenAsync(long usuarioId, CancellationToken cancellationToken);
}

public sealed class AuthService(
    ContextoBanco contexto,
    IOptions<JwtOptions> jwtOptions) : IAuthService
{
    private readonly JwtOptions _jwt = jwtOptions.Value;

    public async Task<UsuarioResponse> RegistrarAsync(
        RegistrarUsuarioRequest request,
        CancellationToken cancellationToken)
    {
        var email = NormalizarEmail(request.Email);
        if (await contexto.Usuarios.AnyAsync(u => u.Email == email, cancellationToken))
            throw new InvalidOperationException("Já existe um usuário cadastrado com este e-mail.");

        var cnpjLimpo = new string((request.Cnpj ?? string.Empty).Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        if (cnpjLimpo.Length != 14)
        {
            cnpjLimpo = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString().PadLeft(14, '0')[..14];
        }

        var razaoSocial = string.IsNullOrWhiteSpace(request.RazaoSocial)
            ? $"{request.Nome.Trim()} LTDA"
            : request.RazaoSocial.Trim();

        var portesValidos = new HashSet<string> { "MEI", "ME", "EPP", "MEDIO", "GRANDE" };
        var porte = portesValidos.Contains((request.Porte ?? "").ToUpperInvariant())
            ? request.Porte!.ToUpperInvariant()
            : "EPP";

        await using var transacao = await contexto.Database.BeginTransactionAsync(cancellationToken);

        var usuario = new Usuario
        {
            Nome = request.Nome.Trim(),
            Email = email,
            HashSenha = BCrypt.Net.BCrypt.HashPassword(request.Senha),
            DataCriacao = DateTime.UtcNow,
            Ativo = true
        };

        contexto.Usuarios.Add(usuario);
        await contexto.SaveChangesAsync(cancellationToken);

        var conn = (MySqlConnection)contexto.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open)
            await conn.OpenAsync(cancellationToken);

        await using var cmdEmpresa = conn.CreateCommand();
        cmdEmpresa.Transaction = (MySqlTransaction)transacao.GetDbTransaction();
        cmdEmpresa.CommandText = @"
            INSERT INTO tb_empresas (nr_cnpj, nm_razao_social, tp_porte)
            VALUES (@Cnpj, @RazaoSocial, @Porte)
            ON DUPLICATE KEY UPDATE nm_razao_social = VALUES(nm_razao_social);
            SELECT id_empresa FROM tb_empresas WHERE nr_cnpj = @Cnpj LIMIT 1;";
        cmdEmpresa.Parameters.AddWithValue("@Cnpj", cnpjLimpo);
        cmdEmpresa.Parameters.AddWithValue("@RazaoSocial", razaoSocial);
        cmdEmpresa.Parameters.AddWithValue("@Porte", porte);

        var idEmpresa = Convert.ToInt64(await cmdEmpresa.ExecuteScalarAsync(cancellationToken));

        await using var cmdVinculo = conn.CreateCommand();
        cmdVinculo.Transaction = (MySqlTransaction)transacao.GetDbTransaction();
        cmdVinculo.CommandText = @"
            INSERT INTO tb_empresas_usuarios (id_empresa, id_usuario, tp_papel, st_vinculo)
            VALUES (@IdEmpresa, @IdUsuario, 'ADMIN', 'ATIVO')
            ON DUPLICATE KEY UPDATE st_vinculo = 'ATIVO', tp_papel = 'ADMIN';";
        cmdVinculo.Parameters.AddWithValue("@IdEmpresa", idEmpresa);
        cmdVinculo.Parameters.AddWithValue("@IdUsuario", usuario.Id);
        await cmdVinculo.ExecuteNonQueryAsync(cancellationToken);

        await transacao.CommitAsync(cancellationToken);
        return MapearUsuario(usuario);
    }

    public async Task<TokenResponse?> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        var usuario = await contexto.Usuarios.SingleOrDefaultAsync(
            item => item.Email == NormalizarEmail(request.Email),
            cancellationToken);

        if (usuario is null || !usuario.Ativo || !BCrypt.Net.BCrypt.Verify(request.Senha, usuario.HashSenha))
            return null;

        return await CriarTokensAsync(usuario, cancellationToken);
    }

    public async Task<TokenResponse?> RenovarTokenAsync(
        RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        var hash = HashToken(request.RefreshToken);
        var usuario = await contexto.Usuarios.SingleOrDefaultAsync(
            item => item.RefreshToken == hash &&
                    item.DataExpiracaoRefreshToken > DateTime.UtcNow,
            cancellationToken);

        if (usuario is null || !usuario.Ativo)
            return null;

        return await CriarTokensAsync(usuario, cancellationToken);
    }

    public async Task RevogarTokenAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var usuario = await contexto.Usuarios.SingleOrDefaultAsync(item => item.Id == usuarioId, cancellationToken)
            ?? throw new KeyNotFoundException("Usuário não encontrado.");

        usuario.RefreshToken = null;
        usuario.DataExpiracaoRefreshToken = null;
        await contexto.SaveChangesAsync(cancellationToken);
    }

    public async Task<UsuarioResponse?> ObterAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var usuario = await contexto.Usuarios.AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == usuarioId && item.Ativo, cancellationToken);
        return usuario is null ? null : MapearUsuario(usuario);
    }

    private async Task<TokenResponse> CriarTokensAsync(Usuario usuario, CancellationToken cancellationToken)
    {
        var agora = DateTimeOffset.UtcNow;
        var accessExpiraEm = agora.AddMinutes(_jwt.AccessTokenMinutes);
        var refreshExpiraEm = agora.AddDays(_jwt.RefreshTokenDays);
        var refreshToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

        usuario.RefreshToken = HashToken(refreshToken);
        usuario.DataExpiracaoRefreshToken = refreshExpiraEm.UtcDateTime;
        await contexto.SaveChangesAsync(cancellationToken);

        var vinculos = await contexto.UsuariosEmpresas
            .Where(item => item.IdUsuario == usuario.Id && item.StatusVinculo == "ATIVO")
            .ToListAsync(cancellationToken);

        var idEmpresaPrincipal = vinculos.FirstOrDefault()?.IdEmpresa ?? 0;

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new(ClaimTypes.Name, usuario.Nome),
            new(ClaimTypes.Email, usuario.Email),
            new("id_empresa", idEmpresaPrincipal.ToString())
        };
        claims.AddRange(vinculos.Select(v => v.Papel).Distinct().Select(papel => new Claim(ClaimTypes.Role, papel)));

        var chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.Key));
        var credenciais = new SigningCredentials(chave, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims,
            expires: accessExpiraEm.UtcDateTime,
            signingCredentials: credenciais);

        return new TokenResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            refreshToken,
            accessExpiraEm,
            refreshExpiraEm);
    }

    private static string NormalizarEmail(string email) => email.Trim().ToLowerInvariant();

    private static string HashToken(string token) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private static UsuarioResponse MapearUsuario(Usuario usuario) =>
        new(usuario.Id, usuario.Nome, usuario.Email);
}
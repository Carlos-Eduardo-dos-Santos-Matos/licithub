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
        if (await contexto.Usuarios.AnyAsync(usuario => usuario.Email == email, cancellationToken))
            throw new InvalidOperationException("Já existe um usuário com este e-mail.");

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

        var papeis = await contexto.UsuariosEmpresas
            .Where(item => item.IdUsuario == usuario.Id &&
                        item.StatusVinculo == "ATIVO")
            .Select(item => item.Papel)
            .Distinct()
            .ToListAsync(cancellationToken);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new(ClaimTypes.Name, usuario.Nome),
            new(ClaimTypes.Email, usuario.Email)
        };
        claims.AddRange(papeis.Select(papel => new Claim(ClaimTypes.Role, papel)));

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

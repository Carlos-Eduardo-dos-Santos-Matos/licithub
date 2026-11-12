namespace licithub_api_usuarios.Configuration;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    public required string Key { get; init; }
    public string Issuer { get; init; } = "licithub";
    public string Audience { get; init; } = "licithub";
    public int AccessTokenMinutes { get; init; } = 15;
    public int RefreshTokenDays { get; init; } = 7;
}

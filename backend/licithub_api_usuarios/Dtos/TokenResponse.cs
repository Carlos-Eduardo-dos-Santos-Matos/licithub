namespace licithub_api_usuarios.Dtos;

public sealed record TokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTimeOffset AccessTokenExpiraEm,
    DateTimeOffset RefreshTokenExpiraEm);

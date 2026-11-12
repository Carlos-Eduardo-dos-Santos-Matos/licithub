using System.ComponentModel.DataAnnotations;

namespace licithub_api_usuarios.Dtos;

public sealed record RefreshTokenRequest
{
    [Required]
    public required string RefreshToken { get; init; }
}

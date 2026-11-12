using System.ComponentModel.DataAnnotations;

namespace licithub_api_usuarios.Dtos;

public sealed record LoginRequest
{
    [Required, EmailAddress, StringLength(254)]
    public required string Email { get; init; }

    [Required]
    public required string Senha { get; init; }
}

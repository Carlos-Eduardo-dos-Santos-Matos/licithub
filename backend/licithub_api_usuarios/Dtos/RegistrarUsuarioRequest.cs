using System.ComponentModel.DataAnnotations;

namespace licithub_api_usuarios.Dtos;

public sealed record RegistrarUsuarioRequest
{
    [Required, StringLength(150, MinimumLength = 2)]
    public required string Nome { get; init; }

    [Required, EmailAddress, StringLength(254)]
    public required string Email { get; init; }

    [Required, StringLength(100, MinimumLength = 8)]
    public required string Senha { get; init; }
}

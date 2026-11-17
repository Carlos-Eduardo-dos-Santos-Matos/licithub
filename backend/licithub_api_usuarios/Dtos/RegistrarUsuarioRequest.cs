using System.ComponentModel.DataAnnotations;

namespace licithub_api_usuarios.Dtos;

public sealed record RegistrarUsuarioRequest(
    [Required, MinLength(2), MaxLength(150)] string Nome,
    [Required, EmailAddress, MaxLength(254)] string Email,
    [Required, MinLength(6), MaxLength(100)] string Senha,
    string? Cnpj = null,
    string? RazaoSocial = null,
    string? Porte = "EPP"
);
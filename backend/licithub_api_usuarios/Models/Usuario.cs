namespace licithub_api_usuarios.Models
{
    public sealed class Usuario
    {
        public long Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string HashSenha { get; set; } = string.Empty;
        public string? RefreshToken { get; set; }
        public DateTime? DataExpiracaoRefreshToken { get; set; }
        public bool Ativo { get; set; } = true;
        public DateTime DataCriacao { get; set; }
    }
}
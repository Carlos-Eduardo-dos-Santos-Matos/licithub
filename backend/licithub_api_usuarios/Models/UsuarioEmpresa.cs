namespace licithub_api_usuarios.Models;

public sealed class UsuarioEmpresa
{
    public long IdEmpresa { get; set; }
    public long IdUsuario { get; set; }
    public string Papel { get; set; } = string.Empty;
    public string StatusVinculo { get; set; } = string.Empty;
}

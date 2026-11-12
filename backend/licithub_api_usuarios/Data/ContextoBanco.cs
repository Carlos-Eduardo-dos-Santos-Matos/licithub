using licithub_api_usuarios.Models;
using Microsoft.EntityFrameworkCore;
namespace licithub_api_usuarios.Data
{
    public class ContextoBanco(DbContextOptions<ContextoBanco> options) : DbContext(options)
    {
        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<UsuarioEmpresa> UsuariosEmpresas { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Usuario>(entity =>
            {
                entity.ToTable("tb_usuarios");
                entity.HasKey(usuario => usuario.Id);
                entity.Property(usuario => usuario.Id).HasColumnName("id_usuario");
                entity.Property(usuario => usuario.Nome).HasColumnName("nm_usuario").HasMaxLength(150).IsRequired();
                entity.Property(usuario => usuario.Email).HasColumnName("ds_email").HasMaxLength(254).IsRequired();
                entity.Property(usuario => usuario.HashSenha).HasColumnName("hs_senha").HasMaxLength(255).IsRequired();
                entity.Property(usuario => usuario.RefreshToken).HasColumnName("cd_refresh_token").HasMaxLength(255);
                entity.Property(usuario => usuario.DataExpiracaoRefreshToken).HasColumnName("dh_expiracao_refresh_token");
                entity.Property(usuario => usuario.Ativo).HasColumnName("fl_ativo");
                entity.Property(usuario => usuario.DataCriacao).HasColumnName("dh_criacao");
                entity.HasIndex(usuario => usuario.Email).IsUnique();
            });

            modelBuilder.Entity<UsuarioEmpresa>(entity =>
            {
                entity.ToTable("tb_empresas_usuarios");
                entity.HasKey(item => new { item.IdEmpresa, item.IdUsuario });
                entity.Property(item => item.IdEmpresa).HasColumnName("id_empresa");
                entity.Property(item => item.IdUsuario).HasColumnName("id_usuario");
                entity.Property(item => item.Papel).HasColumnName("tp_papel");
                entity.Property(item => item.StatusVinculo).HasColumnName("st_vinculo");
            });
        }
    }
}
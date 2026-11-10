using Microsoft.EntityFrameworkCore;
using licithub_api_empresas.Entities;

namespace licithub_api_empresas.Data
{
    public class ContextoBanco (DbContextOptions<ContextoBanco> options)  : DbContext (options)
    {
        public DbSet<Empresa> Empresas { get; set; }
        public DbSet<Usuario> Usuarios { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            
        }
    }
}
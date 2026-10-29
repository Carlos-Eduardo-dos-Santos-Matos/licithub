using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace licithub_api_empresas.Entities
{
    public class Usuario
    {
        public int Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string HashSenha { get; set; } = string.Empty;
        public bool UsuarioAtivo {get;set;} = true;
        public DateTime DataCriacao { get; set; }
    }
}
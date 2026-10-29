using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using licithub_api_empresas.Enums;

namespace licithub_api_empresas.Entities
{
    public class Empresa
    {
        public int Id { get; set; }
        public string NomeFantasia { get; set; } = string.Empty;
        public string RazaoSocial { get; set; } = string.Empty;
        public string Cnpj { get; set; } = string.Empty;
        public Porte Porte { get; set; }
        public string Email { get; set; } = string.Empty;
        public DateTime DataCriacao { get; set; }
    }
}
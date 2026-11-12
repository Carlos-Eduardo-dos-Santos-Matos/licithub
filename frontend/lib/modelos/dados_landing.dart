import 'dart:convert';

/// Dados estruturados em formato JSON para as seções da Landing Page (Tela Inicial).
const String dadosLandingJson = '''
{
  "sobreNos": [
    "A LicitHub é uma empresa de tecnologia especializada em gestão de licitações. Unimos empresas e órgãos públicos, tornando o processo de participar de compras governamentais simples e acessível.",
    "Nossa plataforma monitora editais em todo o Brasil e transforma documentos longos e técnicos em informações claras, para que você decida rápido onde vale a pena concorrer.",
    "Cada licitação é uma nova chance de crescer — e nós ajudamos você a não perder nenhuma."
  ],
  "visaoValores": [
    {
      "icone": "search",
      "titulo": "Busca completa",
      "descricao": "Editais de todo o país reunidos em um só lugar"
    },
    {
      "icone": "document",
      "titulo": "Informação mastigada",
      "descricao": "Resumos claros de cada edital, sem juridiquês"
    },
    {
      "icone": "bell",
      "titulo": "Alertas certeiros",
      "descricao": "Avisos das oportunidades do seu ramo"
    },
    {
      "icone": "shield",
      "titulo": "Segurança",
      "descricao": "Prazos e documentos sempre sob controle"
    },
    {
      "icone": "users",
      "titulo": "Perto do cliente",
      "descricao": "Equipe dedicada ao seu sucesso"
    }
  ],
  "contatos": [
    {
      "icone": "phone",
      "titulo": "Telefone",
      "valor": "(11) 0000-0000"
    },
    {
      "icone": "mail",
      "titulo": "E-mail",
      "valor": "contato@licithub.com.br"
    },
    {
      "icone": "location",
      "titulo": "Endereço",
      "valor": "São Paulo — SP, Brasil"
    },
    {
      "icone": "clock",
      "titulo": "Atendimento",
      "valor": "Segunda a sexta: 9h às 18h"
    }
  ]
}
''';

Map<String, dynamic> obterDadosLanding() {
  return jsonDecode(dadosLandingJson) as Map<String, dynamic>;
}

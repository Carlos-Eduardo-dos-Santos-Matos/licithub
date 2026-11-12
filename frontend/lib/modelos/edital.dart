/// Modelo de dados que representa um Edital de licitação pública.
class Edital {
  final String titulo;
  final String orgao;
  final String objeto;
  final String valor;
  final List<String> itens;

  const Edital({
    required this.titulo,
    required this.orgao,
    required this.objeto,
    required this.valor,
    required this.itens,
  });
}

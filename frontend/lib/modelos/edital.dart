class Edital {
  final int id;
  final String numeroControlePncp;
  final String titulo;
  final String orgao;
  final String cnpjOrgao;
  final String objeto;
  final double valorEstimado;
  final String valor;
  final String uf;
  final String municipio;
  final String situacao;
  final String? dataEncerramento;
  final String? linkOrigem;
  final List<String> itens;

  const Edital({
    required this.id,
    required this.numeroControlePncp,
    required this.titulo,
    required this.orgao,
    this.cnpjOrgao = '',
    required this.objeto,
    this.valorEstimado = 0.0,
    required this.valor,
    this.uf = '',
    this.municipio = '',
    this.situacao = 'Divulgada no PNCP',
    this.dataEncerramento,
    this.linkOrigem,
    this.itens = const [],
  });

  factory Edital.fromJson(Map<String, dynamic> json, String Function(dynamic) formatarMoeda) {
    final modalidade = json['modalidade']?.toString() ?? 'Licitação';
    final numeroEdital = json['numeroEdital']?.toString() ?? '';
    final tituloMontado = numeroEdital.isNotEmpty && numeroEdital != 'S/N'
        ? '$modalidade $numeroEdital'
        : modalidade;

    final valorNum = (json['valorEstimado'] is num)
        ? (json['valorEstimado'] as num).toDouble()
        : double.tryParse(json['valorEstimado']?.toString() ?? '0') ?? 0.0;

    return Edital(
      id: (json['id'] as num?)?.toInt() ?? 0,
      numeroControlePncp: json['numeroControlePncp']?.toString() ?? '',
      titulo: tituloMontado,
      orgao: json['orgao']?.toString() ?? 'Órgão Público',
      cnpjOrgao: json['cnpjOrgao']?.toString() ?? '',
      objeto: json['objeto']?.toString() ?? '',
      valorEstimado: valorNum,
      valor: valorNum > 0 ? formatarMoeda(valorNum) : 'Sigiloso / Não informado',
      uf: json['uf']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      situacao: json['situacao']?.toString() ?? '',
      dataEncerramento: json['dataEncerramentoProposta']?.toString(),
      linkOrigem: json['linkOrigem']?.toString(),
      itens: const [],
    );
  }

  Edital copyWith({List<String>? itens}) {
    return Edital(
      id: id,
      numeroControlePncp: numeroControlePncp,
      titulo: titulo,
      orgao: orgao,
      cnpjOrgao: cnpjOrgao,
      objeto: objeto,
      valorEstimado: valorEstimado,
      valor: valor,
      uf: uf,
      municipio: municipio,
      situacao: situacao,
      dataEncerramento: dataEncerramento,
      linkOrigem: linkOrigem,
      itens: itens ?? this.itens,
    );
  }
}
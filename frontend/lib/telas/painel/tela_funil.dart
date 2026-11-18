import 'package:flutter/material.dart';
import '../../servicos/api_servico.dart';
import '../../servicos/formatadores.dart';

typedef FunnelPage = TelaFunil;
typedef DragTargetFunil = DragTarget<RegistroJson>;
typedef DraggableFunil = Draggable<RegistroJson>;

class TelaFunil extends StatefulWidget {
  const TelaFunil({super.key});

  @override
  State<TelaFunil> createState() => _TelaFunilState();
}

class _TelaFunilState extends State<TelaFunil> {
  bool _carregando = true;
  String? _erro;
  ListaRegistros _cards = [];

  static const ListaRegistros _etapas = [
    {
      'chave': 'INTERESSE',
      'titulo': 'Interesse',
      'cor': Color(0xFF2563EB),
    },
    {
      'chave': 'EM_ANALISE',
      'titulo': 'Em Análise',
      'cor': Color(0xFF0284C7),
    },
    {
      'chave': 'PROPOSTA_ENVIADA',
      'titulo': 'Proposta Enviada',
      'cor': Color(0xFF1D4ED8),
    },
    {
      'chave': 'EMPACADA',
      'titulo': 'Empacada / Pendência',
      'cor': Color(0xFFD97706),
    },
    {
      'chave': 'GANHA',
      'titulo': 'Ganha',
      'cor': Color(0xFF16A34A),
    },
    {
      'chave': 'PERDIDA',
      'titulo': 'Perdida',
      'cor': Color(0xFFDC2626),
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregarFunil();
  }

  Future<void> _carregarFunil() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await listarAcompanhamentosFunil();
      if (!mounted) return;
      setState(() => _cards = dados);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _normalizarStatus(dynamic statusRaw) {
    final s = (statusRaw ?? 'INTERESSE').toString().toUpperCase().trim();
    if (s.contains('ANALISE')) return 'EM_ANALISE';
    if (s.contains('PROPOSTA')) return 'PROPOSTA_ENVIADA';
    if (s.contains('EMPAC') || s.contains('PENDEN') || s.contains('TRAV')) {
      return 'EMPACADA';
    }
    if (s.contains('GANH')) return 'GANHA';
    if (s.contains('PERD') || s.contains('CANCEL')) return 'PERDIDA';
    return 'INTERESSE';
  }

  int _extrairId(RegistroJson card) {
    final raw = card['id'] ?? card['idAcompanhamento'] ?? 0;
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  Future<void> _moverCard(RegistroJson card, String novaEtapa) async {
    final id = _extrairId(card);
    setState(() {
      final idx = _cards.indexWhere((c) => _extrairId(c) == id);
      if (idx != -1) {
        _cards[idx] = {..._cards[idx], 'status': novaEtapa};
      }
    });
    await moverCardFunil(id, novaEtapa);
  }

  Future<void> _confirmarExclusao(RegistroJson card) async {
    final titulo = (card['objeto'] ??
            card['titulo'] ??
            card['orgao'] ??
            'esta licitação')
        .toString();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir licitação do funil?'),
        content: Text(
          'Deseja remover "$titulo" do seu funil de acompanhamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    final id = _extrairId(card);
    await excluirCardFunil(id);
    if (!mounted) return;
    setState(() {
      _cards.removeWhere((c) => _extrairId(c) == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Licitação removida do funil.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corTexto = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final corSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Funil de Disputas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arraste os cards livremente entre etapas ou use o menu de 3 pontinhos para mover e excluir.',
                    style: TextStyle(fontSize: 13.5, color: corSub),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _carregando ? null : _carregarFunil,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Atualizar Funil'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_carregando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_erro != null)
            Expanded(
              child: Center(
                child: Text(
                  _erro!,
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _etapas.map((etapa) {
                    final chave = etapa['chave'] as String;
                    final titulo = etapa['titulo'] as String;
                    final cor = etapa['cor'] as Color;
                    final itensColuna = _cards
                        .where((c) => _normalizarStatus(c['status']) == chave)
                        .toList();

                    return _buildColunaKanban(
                      chave: chave,
                      titulo: titulo,
                      cor: cor,
                      itens: itensColuna,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColunaKanban({
    required String chave,
    required String titulo,
    required Color cor,
    required ListaRegistros itens,
    required bool isDark,
  }) {
    final corColuna =
        isDark ? const Color(0xFF111827) : const Color(0xFFEFF4FA);
    final corBorda =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFD6E0EE);

    return DragTargetFunil(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _moverCard(details.data, chave),
      builder: (context, candidateData, _) {
        final destacando = candidateData.isNotEmpty;
        return Container(
          width: 295,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: destacando ? cor.withValues(alpha: 0.14) : corColuna,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: destacando ? cor : corBorda,
              width: destacando ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${itens.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: itens.isEmpty
                    ? Center(
                        child: Text(
                          'Arraste um edital para cá',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final card = itens[index];
                          return _buildCardArrastavel(card, isDark);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardArrastavel(RegistroJson card, bool isDark) {
    final widgetCard = _buildCardVisual(card, isDark);
    return DraggableFunil(
      data: card,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 270, child: widgetCard),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: widgetCard),
      child: widgetCard,
    );
  }

  Widget _buildCardVisual(RegistroJson card, bool isDark) {
    final orgao =
        (card['orgao'] ?? card['nomeOrgao'] ?? 'Órgão Público').toString();
    final objeto =
        (card['objeto'] ?? card['descricao'] ?? 'Edital em acompanhamento')
            .toString();
    final uf = (card['uf'] ?? '').toString();
    final valor = card['valorEstimado'] ?? card['valorTotalEstimado'];
    final valorFormatado =
        (valor is num && valor > 0) ? formatarMoeda(valor) : 'Valor a definir';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  orgao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções do card',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                onSelected: (opcao) {
                  if (opcao == 'EXCLUIR') {
                    _confirmarExclusao(card);
                  } else {
                    _moverCard(card, opcao);
                  }
                },
                itemBuilder: (context) => [
                  ..._etapas.map(
                    (e) => PopupMenuItem<String>(
                      value: e['chave'] as String,
                      child: Text('Mover para: ${e['titulo']}'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'EXCLUIR',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Excluir do funil',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            objeto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                valorFormatado,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
              if (uf.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    uf,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
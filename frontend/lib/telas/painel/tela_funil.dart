import 'package:flutter/material.dart';
import '../../configuracoes/tema_app.dart';
import '../../servicos/api_servico.dart';
import '../../servicos/formatadores.dart';

typedef FunilPage = TelaFunil;

class TelaFunil extends StatefulWidget {
  const TelaFunil({super.key});

  @override
  State<TelaFunil> createState() => _TelaFunilState();
}

class _TelaFunilState extends State<TelaFunil> {
  late Future<List<Map<String, dynamic>>> _funilFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _funilFuture = listarAcompanhamentosFunil();
    });
  }

  Future<void> _avancarEtapa(int idAcompanhamento, String proximoStatus) async {
    try {
      await moverCardFunil(idAcompanhamento, proximoStatus);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Funil de Disputa',
                style: TextStyle(
                  fontFamily: TemaApp.fonteSerifada,
                  fontFamilyFallback: TemaApp.fallbackSerifada,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar funil',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>> (
              future: _funilFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 15),
                    ),
                  );
                }

                final itens = snapshot.data ?? [];
                final mapeados = itens.where((i) => i['status'] == 'INTERESSE' || i['status'] == 'ANALISANDO').toList();
                final documentacao = itens.where((i) => i['status'] == 'PROPOSTA_EM_PREPARO').toList();
                final participando = itens.where((i) => i['status'] == 'PARTICIPANDO').toList();
                final resultados = itens.where((i) => i['status'] == 'GANHOU' || i['status'] == 'PERDEU').toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColuna('Mapeados', mapeados, proximoStatus: 'PROPOSTA_EM_PREPARO', labelAcao: 'Iniciar Proposta'),
                    const SizedBox(width: 20),
                    _buildColuna('Documentação', documentacao, proximoStatus: 'PARTICIPANDO', labelAcao: 'Pronto p/ Lance'),
                    const SizedBox(width: 20),
                    _buildColuna('Em Disputa', participando, proximoStatus: 'GANHOU', labelAcao: 'Marcar Ganho'),
                    const SizedBox(width: 20),
                    _buildColuna('Resultados', resultados),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColuna(
    String titulo,
    List<Map<String, dynamic>> cards, {
    String? proximoStatus,
    String? labelAcao,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$titulo (${cards.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cards.isEmpty
                  ? const Center(
                      child: Text('Nenhum edital nesta etapa', style: TextStyle(color: Colors.black38, fontSize: 13)),
                    )
                  : ListView.separated(
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final card = cards[idx];
                        final idAcomp = (card['idAcompanhamento'] as num).toInt();
                        final orgao = card['orgao']?.toString() ?? '';
                        final objeto = card['objeto']?.toString() ?? '';
                        final valor = formatarMoeda(card['valorEstimado']);
                        final status = card['status']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(orgao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const SizedBox(height: 4),
                              Text(objeto, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                              const SizedBox(height: 8),
                              Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10B981), fontSize: 13)),
                              if (status == 'GANHOU' || status == 'PERDEU') ...[
                                const SizedBox(height: 8),
                                Text(
                                  status == 'GANHOU' ? '[GANHO]' : '[PERDIDO]',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: status == 'GANHOU' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                              if (proximoStatus != null && labelAcao != null) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _avancarEtapa(idAcomp, proximoStatus),
                                    child: Text(labelAcao, style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../modelos/edital.dart';
import '../../servicos/api_servico.dart';

typedef BuscarEditaisPage = TelaBuscarEditais;

class TelaBuscarEditais extends StatefulWidget {
  final ValueChanged<Edital> onAnalisar;

  const TelaBuscarEditais({super.key, required this.onAnalisar});

  @override
  State<TelaBuscarEditais> createState() => _TelaBuscarEditaisState();
}

class _TelaBuscarEditaisState extends State<TelaBuscarEditais> {
  final TextEditingController _buscaController = TextEditingController();
  String? _ufSelecionada;
  String? _modalidadeSelecionada;
  String? _situacaoSelecionada;
  bool _apenasAcima100k = false;
  late Future<List<Edital>> _editaisFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _carregar() {
    setState(() {
      _editaisFuture = buscarLicitacoes(
        termo: _buscaController.text,
        uf: _ufSelecionada,
        valorMinimo: _apenasAcima100k ? 100000 : null,
        modalidade: _modalidadeSelecionada,
        situacao: _situacaoSelecionada,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _buscaController,
                    onSubmitted: (_) => _carregar(),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por objeto, órgão público ou município...',
                      hintStyle: TextStyle(color: Colors.black38),
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _carregar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Pesquisar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('São Paulo (SP)'),
                selected: _ufSelecionada == 'SP',
                onSelected: (sel) {
                  _ufSelecionada = sel ? 'SP' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Rio de Janeiro (RJ)'),
                selected: _ufSelecionada == 'RJ',
                onSelected: (sel) {
                  _ufSelecionada = sel ? 'RJ' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Minas Gerais (MG)'),
                selected: _ufSelecionada == 'MG',
                onSelected: (sel) {
                  _ufSelecionada = sel ? 'MG' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Acima de R\$ 100k'),
                selected: _apenasAcima100k,
                onSelected: (sel) {
                  _apenasAcima100k = sel;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Pregão eletrônico'),
                selected: _modalidadeSelecionada == 'Pregão',
                onSelected: (sel) {
                  _modalidadeSelecionada = sel ? 'Pregão' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Concorrência'),
                selected: _modalidadeSelecionada == 'Concorrência',
                onSelected: (sel) {
                  _modalidadeSelecionada = sel ? 'Concorrência' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Dispensa'),
                selected: _modalidadeSelecionada == 'Dispensa',
                onSelected: (sel) {
                  _modalidadeSelecionada = sel ? 'Dispensa' : null;
                  _carregar();
                },
              ),
              FilterChip(
                label: const Text('Divulgada no PNCP'),
                selected: _situacaoSelecionada == 'Divulgada no PNCP',
                onSelected: (sel) {
                  _situacaoSelecionada = sel ? 'Divulgada no PNCP' : null;
                  _carregar();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Edital>>(
              future: _editaisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao consultar licitações: ${snapshot.error}'),
                  );
                }

                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma licitação encontrada para os filtros aplicados.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildCardEdital(lista[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEdital(Edital edital) {
    final local = [edital.municipio, edital.uf].where((s) => s.isNotEmpty).join(' - ');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${edital.orgao} — ${edital.titulo}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                if (local.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$local • PNCP: ${edital.numeroControlePncp}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  edital.objeto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text('Valor Estimado:', style: TextStyle(fontSize: 12.5, color: Colors.black45)),
                Text(
                  edital.valor,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => widget.onAnalisar(edital),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Analisar Edital', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
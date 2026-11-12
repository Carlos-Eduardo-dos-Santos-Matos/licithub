import 'package:flutter/material.dart';
import '../../configuracoes/tema_app.dart';

typedef FunilPage = TelaFunil;

/// Aba 3: Quadro Kanban do Funil de Disputa de licitações.
class TelaFunil extends StatelessWidget {
  const TelaFunil({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn(
                  titulo: 'Mapeados',
                  cards: [
                    _buildKanbanCard('Prefeitura de SP - Limpeza', 'R\$ 250k'),
                    _buildKanbanCard(
                      'Governo do Estado de SP - Software',
                      'R\$ 840k',
                    ),
                    _buildKanbanCard(
                      'Secretaria de Educação - Uniformes',
                      'R\$ 120k',
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Documentação',
                  cards: [
                    _buildKanbanCard(
                      'Hospital das Clínicas - Insumos',
                      'R\$ 120k',
                      progresso: 0.75,
                      textoProgresso: '75% completo',
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Pronto para Lance',
                  cards: [
                    _buildKanbanCard('Tribunal de Justiça - TI', 'R\$ 95k'),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  titulo: 'Resultados',
                  cards: [
                    _buildKanbanCard(
                      'Câmara de SP - Móveis',
                      '(R\$ 45k)',
                      tagResultado: '[Ganho]',
                      corTag: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required String titulo,
    required List<Widget> cards,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$titulo (${cards.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanCard(
    String titulo,
    String valor, {
    double? progresso,
    String? textoProgresso,
    String? tagResultado,
    Color? corTag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          if (progresso != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              textoProgresso ?? '',
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
          if (tagResultado != null) ...[
            const SizedBox(height: 12),
            Text(
              tagResultado,
              style: TextStyle(
                color: corTag,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

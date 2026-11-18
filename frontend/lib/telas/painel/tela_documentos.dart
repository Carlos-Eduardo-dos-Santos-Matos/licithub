import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../servicos/api_servico.dart';

typedef DocumentsPage = TelaDocumentos;

class TelaDocumentos extends StatefulWidget {
  const TelaDocumentos({super.key});

  @override
  State<TelaDocumentos> createState() => _TelaDocumentosState();
}

class _TelaDocumentosState extends State<TelaDocumentos> {
  List<DocumentoEmpresa> _documentos = [];
  bool _carregando = true;
  String _filtroStatus = 'TODOS';

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  Future<void> _carregarDocumentos() async {
    setState(() => _carregando = true);
    final lista = await listarDocumentosEmpresa();
    if (!mounted) return;
    setState(() {
      _documentos = lista;
      _carregando = false;
    });
  }

  String _statusValidade(DocumentoEmpresa doc) {
    if (doc.dataValidade == null) return 'VALIDO';
    final hoje = DateTime.now();
    final limiteHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final validade = DateTime(
      doc.dataValidade!.year,
      doc.dataValidade!.month,
      doc.dataValidade!.day,
    );
    final dias = validade.difference(limiteHoje).inDays;
    if (dias < 0) return 'VENCIDO';
    if (dias <= 15) return 'VENCENDO';
    return 'VALIDO';
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Sem validade';
    final d = data.day.toString().padLeft(2, '0');
    final m = data.month.toString().padLeft(2, '0');
    return '$d/$m/${data.year}';
  }

  void _baixarDocumento(DocumentoEmpresa doc) {
    if (doc.conteudoBase64.isEmpty) return;
    final bytes = base64Decode(doc.conteudoBase64);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', doc.nomeArquivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _abrirModalUpload() async {
    final tituloCtrl = TextEditingController();
    DateTime? dataValidade = DateTime.now().add(const Duration(days: 90));
    bool semValidade = false;
    String? nomeArquivo;
    int tamanhoArquivo = 0;
    String? conteudoBase64;
    String? erroForm;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Enviar Novo Documento / Certidão'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título do documento *',
                      hintText: 'Ex: Certidão Negativa Federal (CND)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: semValidade
                              ? null
                              : () async {
                                  final escolhida = await showDatePicker(
                                    context: context,
                                    initialDate: dataValidade ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2040),
                                  );
                                  if (escolhida != null) {
                                    setModalState(
                                        () => dataValidade = escolhida);
                                  }
                                },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            semValidade
                                ? 'Validade indeterminada'
                                : 'Validade: ${_formatarData(dataValidade)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: semValidade,
                    title: const Text(
                      'Documento sem data de validade',
                      style: TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) =>
                        setModalState(() => semValidade = v ?? false),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final input = html.FileUploadInputElement()
                          ..accept = '.pdf,.png,.jpg,.jpeg';
                        input.click();
                        await input.onChange.first;
                        final file = input.files?.first;
                        if (file == null) return;

                        final reader = html.FileReader();
                        reader.readAsDataUrl(file);
                        await reader.onLoadEnd.first;

                        final dataUrl = reader.result?.toString() ?? '';
                        final idx = dataUrl.indexOf(',');
                        if (idx != -1) {
                          setModalState(() {
                            nomeArquivo = file.name;
                            tamanhoArquivo = file.size;
                            conteudoBase64 = dataUrl.substring(idx + 1);
                            erroForm = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        nomeArquivo == null
                            ? 'Selecionar arquivo (PDF, PNG, JPG)'
                            : '$nomeArquivo (${(tamanhoArquivo / 1024).toStringAsFixed(1)} KB)',
                      ),
                    ),
                  ),
                  if (erroForm != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      erroForm!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tituloCtrl.text.trim().isEmpty) {
                    setModalState(() => erroForm =
                        'Informe um título para identificar o documento.');
                    return;
                  }
                  if (nomeArquivo == null || conteudoBase64 == null) {
                    setModalState(
                        () => erroForm = 'Selecione um arquivo para enviar.');
                    return;
                  }

                  final partesNome = nomeArquivo!.split('.');
                  final ext = partesNome.length > 1
                      ? partesNome.last.toLowerCase()
                      : 'pdf';

                  final novoDoc = DocumentoEmpresa(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titulo: tituloCtrl.text.trim(),
                    nomeArquivo: nomeArquivo!,
                    extensao: ext,
                    tamanhoBytes: tamanhoArquivo,
                    dataEnvio: DateTime.now(),
                    dataValidade: semValidade ? null : dataValidade,
                    conteudoBase64: conteudoBase64!,
                  );

                  await salvarDocumentoEmpresa(novoDoc);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  await _carregarDocumentos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004CA3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar Documento'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarExclusaoDoc(DocumentoEmpresa doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir documento?'),
        content: Text('Deseja excluir "${doc.titulo}" permanentemente?'),
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
    if (ok == true) {
      await excluirDocumentoEmpresa(doc.id);
      await _carregarDocumentos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corTexto = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final corSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final filtrados = _documentos.where((doc) {
      if (_filtroStatus == 'TODOS') return true;
      return _statusValidade(doc) == _filtroStatus;
    }).toList();

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
                    'Documentos e Certidões',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle certidões negativas, contratos e prazos de validade da sua empresa.',
                    style: TextStyle(fontSize: 13.5, color: corSub),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _abrirModalUpload,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Enviar Documento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004CA3),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildChipFiltro('TODOS', 'Todos (${_documentos.length})'),
              _buildChipFiltro('VALIDO', 'Válidos'),
              _buildChipFiltro('VENCENDO', 'Vencem em até 15 dias'),
              _buildChipFiltro('VENCIDO', 'Vencidos'),
            ],
          ),
          const SizedBox(height: 20),
          if (_carregando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filtrados.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 54, color: corSub),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum documento encontrado nesta categoria.',
                      style: TextStyle(fontSize: 15, color: corSub),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _abrirModalUpload,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Fazer primeiro upload'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (context, index) {
                  final doc = filtrados[index];
                  return _buildItemDocumento(doc, isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String valor, String label) {
    final selecionado = _filtroStatus == valor;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      onSelected: (_) => setState(() => _filtroStatus = valor),
    );
  }

  Widget _buildItemDocumento(DocumentoEmpresa doc, bool isDark) {
    final status = _statusValidade(doc);
    late final Color corStatus;
    late final String textoStatus;

    if (status == 'VENCIDO') {
      corStatus = const Color(0xFFDC2626);
      textoStatus = 'Vencido';
    } else if (status == 'VENCENDO') {
      corStatus = const Color(0xFFD97706);
      textoStatus = 'Vence em breve';
    } else {
      corStatus = const Color(0xFF16A34A);
      textoStatus = 'Válido';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF004CA3).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arquivo: ${doc.nomeArquivo} • Enviado em ${_formatarData(doc.dataEnvio)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  textoStatus,
                  style: TextStyle(
                    color: corStatus,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Validade: ${_formatarData(doc.dataValidade)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Baixar documento',
            onPressed: () => _baixarDocumento(doc),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Excluir documento',
            onPressed: () => _confirmarExclusaoDoc(doc),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}
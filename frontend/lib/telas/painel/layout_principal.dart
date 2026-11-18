import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../componentes/menu_lateral.dart';
import '../../configuracoes/tema_app.dart';
import '../../modelos/edital.dart';
import '../../servicos/api_servico.dart';
import 'tela_buscar_editais.dart';
import 'tela_dashboard.dart';
import 'tela_detalhes_edital.dart';
import 'tela_documentos.dart';
import 'tela_funil.dart';

typedef MainLayout = LayoutPrincipal;

class LayoutPrincipal extends StatefulWidget {
  const LayoutPrincipal({super.key});

  @override
  State<LayoutPrincipal> createState() => _LayoutPrincipalState();
}

class _LayoutPrincipalState extends State<LayoutPrincipal> {
  int _selectedIndex = 0;
  Edital? _editalSelecionado;

  void _sairDaConta() async {
    await SessaoUsuario.limpar();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _abrirModalPerfil() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DialogPerfilUsuario(
        onSalvo: () {
          if (mounted) setState(() {});
        },
        onExcluirConta: () async {
          Navigator.of(dialogContext).pop();
          _sairDaConta();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundoPainel =
        isDark ? const Color(0xFF090E1A) : const Color(0xFFF4F7F9);
    final corBarraSuperior = isDark ? const Color(0xFF111827) : Colors.white;
    final corBorda = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final List<Widget> pages = [
      const TelaDashboard(),
      TelaBuscarEditais(
        onAnalisar: (edital) {
          setState(() {
            _editalSelecionado = edital;
          });
        },
      ),
      const TelaFunil(),
      const TelaDocumentos(),
    ];

    return Scaffold(
      body: Row(
        children: [
          MenuLateral(
            indiceSelecionado: _selectedIndex,
            exibindoDetalhes: _editalSelecionado != null,
            aoSelecionarItem: (index) {
              setState(() {
                _selectedIndex = index;
                _editalSelecionado = null;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildBarraSuperior(
                  isDark: isDark,
                  corFundo: corBarraSuperior,
                  corBorda: corBorda,
                ),
                Expanded(
                  child: Container(
                    color: corFundoPainel,
                    child: Stack(
                      children: [
                        Offstage(
                          offstage: _editalSelecionado != null,
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: pages,
                          ),
                        ),
                        if (_editalSelecionado != null)
                          TelaDetalhesEdital(
                            edital: _editalSelecionado!,
                            onBack: () {
                              setState(() {
                                _editalSelecionado = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraSuperior({
    required bool isDark,
    required Color corFundo,
    required Color corBorda,
  }) {
    final corTexto = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final corSubtexto =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iniciais = SessaoUsuario.nomeUsuario.trim().isNotEmpty
        ? SessaoUsuario.nomeUsuario.trim()[0].toUpperCase()
        : 'U';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: corFundo,
        border: Border(bottom: BorderSide(color: corBorda)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: acessibilidadeApp.ocultarDadosSensiveis
                ? 'LGPD Ativa: Dados sensíveis mascarados (clique para revelar)'
                : 'Dados sensíveis visíveis (clique para proteger)',
            child: InkWell(
              onTap: () => acessibilidadeApp.alternarProtecaoDados(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEEF3FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFD6E0EE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      acessibilidadeApp.ocultarDadosSensiveis
                          ? Icons.shield_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CNPJ: ${acessibilidadeApp.mascararCnpj(SessaoUsuario.cnpjEmpresa)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: corTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            label: 'Diminuir tamanho da fonte',
            button: true,
            child: IconButton(
              tooltip: 'Diminuir fonte (A-)',
              onPressed: () => acessibilidadeApp.diminuirFonte(),
              icon: Text(
                'A-',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: corTexto,
                ),
              ),
            ),
          ),
          Semantics(
            label: 'Aumentar tamanho da fonte',
            button: true,
            child: IconButton(
              tooltip: 'Aumentar fonte (A+)',
              onPressed: () => acessibilidadeApp.aumentarFonte(),
              icon: Text(
                'A+',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: corTexto,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: isDark ? 'Ativar modo claro' : 'Ativar modo escuro',
            button: true,
            child: OutlinedButton.icon(
              onPressed: () => acessibilidadeApp.alternarTema(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 17,
              ),
              label: Text(
                isDark ? 'Modo Claro' : 'Modo Escuro',
                style:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: corTexto,
                side: BorderSide(color: corBorda),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: corBorda),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            tooltip: 'Menu da conta e perfil',
            offset: const Offset(0, 48),
            onSelected: (valor) {
              if (valor == 'perfil') {
                _abrirModalPerfil();
              } else if (valor == 'lgpd') {
                acessibilidadeApp.alternarProtecaoDados();
              } else if (valor == 'sair') {
                _sairDaConta();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SessaoUsuario.nomeUsuario,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: corTexto,
                      ),
                    ),
                    Text(
                      acessibilidadeApp
                          .mascararEmail(SessaoUsuario.emailUsuario),
                      style: TextStyle(fontSize: 12, color: corSubtexto),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Meu Perfil e Foto'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'lgpd',
                child: Row(
                  children: [
                    Icon(
                      acessibilidadeApp.ocultarDadosSensiveis
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      acessibilidadeApp.ocultarDadosSensiveis
                          ? 'Revelar dados sensíveis'
                          : 'Ocultar dados (LGPD)',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
                    SizedBox(width: 10),
                    Text(
                      'Sair da conta',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                _buildAvatarUsuario(iniciais, raio: 18),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SessaoUsuario.nomeUsuario,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: corTexto,
                      ),
                    ),
                    Text(
                      SessaoUsuario.razaoSocial,
                      style: TextStyle(fontSize: 11, color: corSubtexto),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, size: 18, color: corSubtexto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarUsuario(String iniciais, {double raio = 18}) {
    final foto = SessaoUsuario.fotoPerfilBase64;
    if (foto != null && foto.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: raio,
          backgroundImage: MemoryImage(base64Decode(foto)),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      radius: raio,
      backgroundColor: const Color(0xFF004CA3),
      child: Text(
        iniciais,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: raio * 0.78,
        ),
      ),
    );
  }
}

class _DialogPerfilUsuario extends StatefulWidget {
  final VoidCallback onSalvo;
  final VoidCallback onExcluirConta;

  const _DialogPerfilUsuario({
    required this.onSalvo,
    required this.onExcluirConta,
  });

  @override
  State<_DialogPerfilUsuario> createState() => _DialogPerfilUsuarioState();
}

class _DialogPerfilUsuarioState extends State<_DialogPerfilUsuario> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _razaoCtrl;
  late final TextEditingController _cnpjCtrl;
  late final TextEditingController _telefoneCtrl;
  final TextEditingController _novaSenhaCtrl = TextEditingController();
  String? _fotoBase64;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: SessaoUsuario.nomeUsuario);
    _razaoCtrl = TextEditingController(text: SessaoUsuario.razaoSocial);
    _cnpjCtrl = TextEditingController(text: SessaoUsuario.cnpjEmpresa);
    _telefoneCtrl = TextEditingController(text: SessaoUsuario.telefoneContato);
    _fotoBase64 = SessaoUsuario.fotoPerfilBase64;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _razaoCtrl.dispose();
    _cnpjCtrl.dispose();
    _telefoneCtrl.dispose();
    _novaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarFoto() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;

    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoadEnd.first;

    final dataUrl = reader.result?.toString() ?? '';
    final idx = dataUrl.indexOf(',');
    if (idx != -1 && mounted) {
      setState(() {
        _fotoBase64 = dataUrl.substring(idx + 1);
      });
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_nomeCtrl.text.trim().isNotEmpty) {
      SessaoUsuario.nomeUsuario = _nomeCtrl.text.trim();
    }
    if (_razaoCtrl.text.trim().isNotEmpty) {
      SessaoUsuario.razaoSocial = _razaoCtrl.text.trim();
    }
    if (_cnpjCtrl.text.trim().isNotEmpty) {
      SessaoUsuario.cnpjEmpresa = _cnpjCtrl.text.trim();
    }
    SessaoUsuario.telefoneContato = _telefoneCtrl.text.trim();
    SessaoUsuario.fotoPerfilBase64 = _fotoBase64;

    await SessaoUsuario.salvarSessao();
    widget.onSalvo();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil e preferências atualizados com sucesso.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Meu Perfil, Foto e Privacidade (LGPD)'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF004CA3),
                    backgroundImage:
                        (_fotoBase64 != null && _fotoBase64!.isNotEmpty)
                            ? MemoryImage(base64Decode(_fotoBase64!))
                            : null,
                    child: (_fotoBase64 == null || _fotoBase64!.isEmpty)
                        ? Text(
                            _nomeCtrl.text.isNotEmpty
                                ? _nomeCtrl.text[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selecionarFoto,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: const Text('Alterar Foto de Perfil'),
                      ),
                      if (_fotoBase64 != null && _fotoBase64!.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _fotoBase64 = null),
                          child: const Text(
                            'Remover foto',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _razaoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Razão Social da Empresa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cnpjCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _telefoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        hintText: '(13) 99999-0000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _novaSenhaCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF004CA3).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF004CA3).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Conformidade LGPD: seus dados empresariais são isolados por token JWT e mascarados na tela.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExcluirConta,
                      child: const Text(
                        'Encerrar sessão',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvarAlteracoes,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004CA3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar Alterações'),
        ),
      ],
    );
  }
}
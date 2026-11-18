import 'package:flutter/material.dart';
import '../../componentes/ilustracoes/fundo_login_painter.dart';
import '../../componentes/logo_licithub.dart';
import '../../configuracoes/tema_app.dart';
import '../../servicos/api_servico.dart';

typedef LoginPage = TelaLogin;

class TelaLogin extends StatefulWidget {
  final ValueChanged<String>? onLoginSuccess;
  final VoidCallback? onGoogleLogin;

  const TelaLogin({
    super.key,
    this.onLoginSuccess,
    this.onGoogleLogin,
  });

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _modoCadastro = false;
  bool _carregando = false;
  String _porteSelecionado = 'EPP';
  String? _mensagemFeedback;

  @override
  void dispose() {
    _nomeController.dispose();
    _razaoSocialController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submeterFormulario() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _mensagemFeedback = 'Preencha seu e-mail e sua senha.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _mensagemFeedback = 'Informe um endereço de e-mail válido.');
      return;
    }
    if (senha.length < 6) {
      setState(() => _mensagemFeedback = 'A senha deve possuir pelo menos 6 caracteres.');
      return;
    }

    if (_modoCadastro && _nomeController.text.trim().isEmpty) {
      setState(() => _mensagemFeedback = 'Informe seu nome completo para criar a conta.');
      return;
    }

    setState(() {
      _carregando = true;
      _mensagemFeedback = null;
    });

    try {
      if (_modoCadastro) {
        await registrarEAcessar(
          nome: _nomeController.text.trim(),
          email: email,
          senha: senha,
          cnpj: _cnpjController.text.trim(),
          razaoSocial: _razaoSocialController.text.trim(),
          porte: _porteSelecionado,
        );
      } else {
        await autenticarUsuario(email: email, senha: senha);
      }

      if (!mounted) return;
      widget.onLoginSuccess?.call(email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemFeedback = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1, child: _buildPainelDestaque(isDesktop: true)),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                      child: _buildAreaFormulario(),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPainelDestaque(isDesktop: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Center(child: _buildAreaFormulario()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPainelDestaque({required bool isDesktop}) {
    return Container(
      constraints: BoxConstraints(minHeight: isDesktop ? double.infinity : 320),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.52, 1.0],
          colors: [Color(0xFF061B49), Color(0xFF00459E), Color(0xFF006EE6)],
        ),
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: const FundoLoginPainter(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 56 : 28,
              vertical: isDesktop ? 44 : 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LogoLicitHub(
                  primaryColor: Colors.white,
                  subtitleColor: Color(0xFFD6E6FF),
                  titleFontSize: 25,
                  subtitleFontSize: 9.0,
                ),
                const SizedBox(height: 36),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todas as licitações do\npaís, em um só lugar.',
                        style: TextStyle(
                          fontFamily: TemaApp.fonteSerifada,
                          fontFamilyFallback: TemaApp.fallbackSerifada,
                          fontSize: isDesktop ? 38 : 28,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Integração direta com o PNCP, acompanhamento por empresa e gestão completa das suas propostas.',
                        style: TextStyle(fontSize: 15, color: Color(0xFFC4DBF7), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const Text('© 2026 LicitHub', style: TextStyle(fontSize: 12, color: Color(0xFF8FB4E5))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaFormulario() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LogoLicitHub(
            primaryColor: Color(0xFF0A2547),
            subtitleColor: Color(0xFF0A2547),
            titleFontSize: 28,
            subtitleFontSize: 10.0,
          ),
          const SizedBox(height: 24),
          Text(
            _modoCadastro ? 'Criar conta empresarial' : 'Bem-vindo de volta',
            style: const TextStyle(
              fontFamily: TemaApp.fonteSerifada,
              fontFamilyFallback: TemaApp.fallbackSerifada,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _modoCadastro
                ? 'Cadastre seu usuário e vincule sua empresa ao LicitHub.'
                : 'Entre com suas credenciais para acessar o painel.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 22),
          if (_modoCadastro) ...[
            _buildCampo('Nome completo *', 'Seu nome', _nomeController),
            const SizedBox(height: 14),
            _buildCampo('Razão Social da Empresa', 'Ex: Tech Solutions LTDA', _razaoSocialController),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCampo('CNPJ (14 dígitos)', '00000000000191', _cnpjController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Porte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _porteSelecionado,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFEEF3FA),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        items: const ['MEI', 'ME', 'EPP', 'MEDIO', 'GRANDE']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => _porteSelecionado = v ?? 'EPP'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _buildCampo('E-mail *', 'voce@empresa.com.br', _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _buildCampo('Senha *', 'Mínimo 6 caracteres', _senhaController,
              obscure: true, onSubmitted: (_) => _submeterFormulario()),
          if (_mensagemFeedback != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _mensagemFeedback!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _carregando ? null : _submeterFormulario,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004CA3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _modoCadastro ? 'Criar conta e entrar' : 'Entrar',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: _carregando
                  ? null
                  : () {
                      setState(() {
                        _modoCadastro = !_modoCadastro;
                        _mensagemFeedback = null;
                      });
                    },
              child: Text(
                _modoCadastro
                    ? 'Já possui conta? Fazer login'
                    : 'Não tem uma conta? Cadastre sua empresa',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16437E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFEEF3FA),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD6E0EE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF004CA3), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
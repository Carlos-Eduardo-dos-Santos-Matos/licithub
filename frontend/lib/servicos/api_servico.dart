
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/edital.dart';
import 'formatadores.dart';

const String apiLicitacoesUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5173',
);

const String apiUsuariosUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: 'http://localhost:5174',
);

class SessaoUsuario {
  static String? accessToken;
  static String? refreshToken;
  static String nomeUsuario = 'Usuário LicitHub';
  static String emailUsuario = '';

  static bool get estaAutenticado =>
      accessToken != null && accessToken!.isNotEmpty;

  static Map<String, String> get headersAutenticados => {
        'Content-Type': 'application/json',
        if (estaAutenticado) 'Authorization': 'Bearer $accessToken',
      };

  static void limpar() {
    accessToken = null;
    refreshToken = null;
    nomeUsuario = 'Usuário LicitHub';
    emailUsuario = '';
  }
}

Future<void> autenticarUsuario({
  required String email,
  required String senha,
}) async {
  final respLogin = await http.post(
    Uri.parse('$apiUsuariosUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'senha': senha}),
  );

  if (respLogin.statusCode != 200) {
    final erro = _extrairMensagemErro(
      respLogin.body,
      'E-mail ou senha inválidos.',
    );
    throw Exception(erro);
  }

  final tokens = jsonDecode(respLogin.body) as Map<String, dynamic>;
  SessaoUsuario.accessToken = tokens['accessToken']?.toString();
  SessaoUsuario.refreshToken = tokens['refreshToken']?.toString();
  SessaoUsuario.emailUsuario = email;

  final respMe = await http.get(
    Uri.parse('$apiUsuariosUrl/api/auth/me'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (respMe.statusCode == 200) {
    final perfil = jsonDecode(respMe.body) as Map<String, dynamic>;
    SessaoUsuario.nomeUsuario = perfil['nome']?.toString() ?? email;
  }
}

Future<void> registrarEAcessar({
  required String nome,
  required String email,
  required String senha,
  String? cnpj,
  String? razaoSocial,
  String? porte,
}) async {
  final respReg = await http.post(
    Uri.parse('$apiUsuariosUrl/api/auth/registrar'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nome': nome,
      'email': email,
      'senha': senha,
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'porte': porte ?? 'EPP',
    }),
  );

  if (respReg.statusCode != 201 && respReg.statusCode != 200) {
    final erro = _extrairMensagemErro(
      respReg.body,
      'Não foi possível concluir o cadastro.',
    );
    throw Exception(erro);
  }

  await autenticarUsuario(email: email, senha: senha);
}

Future<Map<String, dynamic>> buscarDadosDashboard() async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/dashboard'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao carregar o dashboard (HTTP ${response.statusCode})',
    );
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> sincronizarPncpAgora() async {
  final response = await http.post(
    Uri.parse('$apiLicitacoesUrl/api/sincronizar'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    final erro = _extrairMensagemErro(
      response.body,
      'Falha na sincronização com o PNCP.',
    );
    throw Exception(erro);
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

// BUSCAR LICITAÇÕES COM FILTROS
Future<List<Edital>> buscarLicitacoes({
  String? termo,
  String? uf,
  double? valorMinimo,
  String? modalidade,
  String? situacao,
  int pagina = 1,
}) async {
  final params = <String, String>{
    'pagina': '$pagina',
    'tamanhoPagina': '25',
    if (termo != null && termo.trim().isNotEmpty)
      'q': termo.trim(),
    if (uf != null && uf.trim().isNotEmpty)
      'uf': uf.trim(),
    if (valorMinimo != null && valorMinimo > 0)
      'valorMin': '$valorMinimo',
    if (modalidade != null && modalidade.trim().isNotEmpty)
      'modalidade': modalidade.trim(),
    if (situacao != null && situacao.trim().isNotEmpty)
      'situacao': situacao.trim(),
  };

  final uri = Uri.parse(
    '$apiLicitacoesUrl/api/licitacoes',
  ).replace(queryParameters: params);

  final response = await http.get(
    uri,
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Erro ao buscar licitações (HTTP ${response.statusCode})',
    );
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final lista = (body['itens'] as List<dynamic>?) ?? [];

  return lista
      .map(
        (item) => Edital.fromJson(
          item as Map<String, dynamic>,
          formatarMoeda,
        ),
      )
      .toList();
}

Future<Edital> buscarDetalhesEdital(Edital base) async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/licitacoes/${base.id}'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode != 200) {
    return base;
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final itensRaw = (body['itens'] as List<dynamic>?) ?? [];

  final itensFormatados = itensRaw.map((item) {
    final m = item as Map<String, dynamic>;
    final nr = m['numeroItem'] ?? '';
    final desc = m['descricao']?.toString() ?? '';
    final qtd = m['quantidade'] ?? 0;
    final un = m['unidade']?.toString() ?? 'UN';
    final vl = m['valorUnitarioEstimado'];

    final vlStr = (vl is num && vl > 0)
        ? ' — Unit.: ${formatarMoeda(vl)}'
        : '';

    return 'Item $nr: $desc ($qtd $un$vlStr)';
  }).toList();

  return base.copyWith(itens: itensFormatados);
}

Future<void> adicionarEditalAoFunil(
  int idLicitacao, {
  String? anotacoes,
}) async {
  final response = await http.post(
    Uri.parse('$apiLicitacoesUrl/api/acompanhamentos'),
    headers: SessaoUsuario.headersAutenticados,
    body: jsonEncode({
      'idLicitacao': idLicitacao,
      'anotacoes': anotacoes,
    }),
  );

  if (response.statusCode == 401) {
    throw Exception(
      'Faça login com uma conta empresarial para adicionar editais ao funil.',
    );
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao salvar edital no funil (HTTP ${response.statusCode})',
    );
  }
}

Future<List<Map<String, dynamic>>> listarAcompanhamentosFunil() async {
  final response = await http.get(
    Uri.parse('$apiLicitacoesUrl/api/acompanhamentos'),
    headers: SessaoUsuario.headersAutenticados,
  );

  if (response.statusCode == 401) {
    throw Exception(
      'Sessão não autenticada. Entre com sua conta para carregar o funil.',
    );
  }

  if (response.statusCode != 200) {
    throw Exception(
      'Erro ao carregar o funil (HTTP ${response.statusCode})',
    );
  }

  return (jsonDecode(response.body) as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

Future<void> moverCardFunil(
  int idAcompanhamento,
  String novoStatus,
) async {
  final response = await http.patch(
    Uri.parse(
      '$apiLicitacoesUrl/api/acompanhamentos/$idAcompanhamento/status',
    ),
    headers: SessaoUsuario.headersAutenticados,
    body: jsonEncode({'status': novoStatus}),
  );

  if (response.statusCode != 204 && response.statusCode != 200) {
    throw Exception(
      'Não foi possível atualizar o status no banco '
      '(HTTP ${response.statusCode})',
    );
  }
}

String _extrairMensagemErro(String body, String padrao) {
  try {
    final json = jsonDecode(body);

    if (json is Map<String, dynamic>) {
      return json['detail']?.toString() ??
          json['title']?.toString() ??
          padrao;
    }
  } catch (_) {}

  return padrao;
}
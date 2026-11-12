import 'dart:convert';
import 'package:http/http.dart' as http;

/// URL base da API C# (.NET) do LicitHub.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5173',
);

/// Consulta os indicadores do dashboard no back-end C# (/api/dashboard).
Future<Map<String, dynamic>> buscarDadosDashboard() async {
  final url = Uri.parse('$apiBaseUrl/api/dashboard');
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception(
      'Falha ao carregar o dashboard (HTTP ${response.statusCode})',
    );
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

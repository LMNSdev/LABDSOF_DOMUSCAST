import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    this.baseUrl = 'http://10.0.2.2:8000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getReportes() async {
    final response = await _client.get(Uri.parse('$baseUrl/reportes/'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Erro ${response.statusCode} ao carregar reportes');
  }

  Future<Map<String, dynamic>> criarReporte({
    required String descricao,
    String? fotoUrl,
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reportes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'descricao': descricao,
        if (fotoUrl != null) 'foto_url': fotoUrl,
        'idempotency_key': idempotencyKey,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ${response.statusCode} ao criar reporte');
  }
}

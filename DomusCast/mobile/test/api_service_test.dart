import 'package:domuscast/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Valor passado ao build com --dart-define=API_BASE_URL=... (vazio se não houver).
const _apiBaseUrlDoBuild = String.fromEnvironment('API_BASE_URL');

void main() {
  test('usa o endereço definido no build (API_BASE_URL) ou, sem ele, o do emulador', () {
    final esperado =
        _apiBaseUrlDoBuild.isEmpty ? 'http://10.0.2.2:8000' : _apiBaseUrlDoBuild;
    expect(ApiService().baseUrl, esperado);
  });

  test('baseUrl explícito prevalece sobre o do build', () {
    expect(ApiService(baseUrl: 'https://x').baseUrl, 'https://x');
  });
}

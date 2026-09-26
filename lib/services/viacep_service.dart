import 'dart:convert';

import 'package:http/http.dart' as http;

class ViaCepAddress {
  ViaCepAddress({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  final String cep;
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;

  bool get isValid => logradouro.isNotEmpty && localidade.isNotEmpty;

  String formatCep() {
    final d = cep.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return cep;
    return '${d.substring(0, 5)}-${d.substring(5)}';
  }

  String lineWithNumber(String? numero) {
    final n = numero?.trim() ?? '';
    final street = logradouro.trim();
    if (n.isEmpty) return street;
    return '$street, $n';
  }

  String fullAddress(String? numero) {
    final parts = <String>[
      lineWithNumber(numero),
      if (bairro.isNotEmpty) bairro,
      if (localidade.isNotEmpty) localidade,
      if (uf.isNotEmpty) uf,
      formatCep(),
    ];
    return parts.join(', ');
  }
}

class ViaCepService {
  Future<ViaCepAddress?> lookup(String cepInput) async {
    final digits = cepInput.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['erro'] == true) return null;
      return ViaCepAddress(
        cep: digits,
        logradouro: (map['logradouro'] as String?)?.trim() ?? '',
        bairro: (map['bairro'] as String?)?.trim() ?? '',
        localidade: (map['localidade'] as String?)?.trim() ?? '',
        uf: (map['uf'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/brazil_cep_uf.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';

void main() {
  test('CEP → UF em vários estados', () {
    expect(ufFromBrazilCep('26271133'), 'RJ');
    expect(ufFromBrazilCep('95010000'), 'RS');
    expect(ufFromBrazilCep('01310100'), 'SP');
    expect(ufFromBrazilCep('40170110'), 'BA');
    expect(ufFromBrazilCep('66010000'), 'PA');
  });

  test('Parada só com CEP 95xxx — hint RS, não RJ', () {
    final p = Parada()
      ..destinationAddress = 'Rua Exemplo 100'
      ..zipcode = '95010000';
    final loc = paradaCityAndUf(p);
    expect(loc.uf, 'RS');
    expect(geocodeQueryForParada(p), contains('RS'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_core.dart';

void main() {
  test('PDF Nova Iguaçu — geocode query usa RJ, não RS', () {
    final p = Parada()
      ..destinationAddress = 'RUA HERCILIA DE JESUS 200 CASA'
      ..bairro = 'JARDIM PALMARES'
      ..city = 'Nova Iguaçu/RJ'
      ..zipcode = '26271133';

    final loc = paradaCityAndUf(p);
    expect(loc.uf, 'RJ');
    expect(loc.city, 'Nova Iguaçu');

    final q = geocodeQueryForParada(p);
    expect(q, contains('RJ'));
    expect(q, isNot(contains(', RS,')));
  });
}

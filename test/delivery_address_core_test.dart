import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

Parada _p({
  String address = '',
  String city = 'Caxias do Sul',
  String zip = '95000-000',
  int stop = 0,
}) {
  return Parada()
    ..destinationAddress = address
    ..city = city
    ..zipcode = zip
    ..stop = stop;
}

void main() {
  test('mesmo AP, nomes diferentes', () {
    final a = _p(
      address: 'Maria Silva, Rua das Flores, 120, apto 2, bloco A',
      zip: '95010-100',
    );
    final b = _p(
      address: 'Joao Souza, Rua das Flores, n 120, ap 2 bloco A',
      zip: '95010-100',
    );
    expect(sameDeliveryLocation(a, b), isTrue);
  });

  test('complementos diferentes no mesmo numero', () {
    final a = _p(address: 'Rua B, 50, casa fundos', city: 'Caxias do Sul');
    final b = _p(address: 'Rua B, 50, portao azul', city: 'Caxias do Sul');
    expect(sameDeliveryLocation(a, b), isTrue);
  });

  test('numeros diferentes nao agrupam', () {
    final a = _p(address: 'Rua C, 10');
    final b = _p(address: 'Rua C, 20');
    expect(sameDeliveryLocation(a, b), isFalse);
  });
}

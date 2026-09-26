import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/delivery_address_key.dart';

void main() {
  test('mesma rua, números diferentes — não agrupa', () {
    final a = Parada()
      ..destinationAddress = 'Rua dos Torneadores, 65, Casa'
      ..city = 'Caxias do Sul/RS';
    final b = Parada()
      ..destinationAddress = 'R dos Torneadores, 59, Em frente ao bar'
      ..city = 'Caxias do Sul/RS';
    expect(sameDeliveryLocation(a, b), isFalse);
    expect(deliveryAddressKey(a), isNot(deliveryAddressKey(b)));
  });

  test('mesmo número, APs diferentes — pins separados', () {
    final a = Parada()
      ..destinationAddress = 'Rua A, 100, Ap 501'
      ..city = 'Nova Iguaçu/RJ'
      ..latitude = -22.75
      ..longitude = -43.45;
    final b = Parada()
      ..destinationAddress = 'Rua A, 100, Ap 502'
      ..city = 'Nova Iguaçu/RJ'
      ..latitude = -22.75
      ..longitude = -43.45;
    expect(deliveryAddressKey(a), isNot(deliveryAddressKey(b)));
    expect(sameDeliveryLocation(a, b), isFalse);
  });

  test('mesmo AP — agrupa pacotes', () {
    final a = Parada()
      ..destinationAddress = 'Rua A, 100, Ap 501'
      ..city = 'Nova Iguaçu/RJ'
      ..latitude = -22.75
      ..longitude = -43.45
      ..ordemExibicao = 1;
    final b = Parada()
      ..destinationAddress = 'Rua A, 100, Apto 501'
      ..city = 'Nova Iguaçu/RJ'
      ..latitude = -22.75
      ..longitude = -43.45
      ..ordemExibicao = 2;
    expect(deliveryAddressKey(a), deliveryAddressKey(b));
    expect(sameDeliveryLocation(a, b), isTrue);
  });
}

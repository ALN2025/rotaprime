import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';
import 'package:rota_prime/utils/import_romaneio_ref.dart';



void main() {

  test('Protocolo PDF — só Nº Entrega na info (não NF/pedido)', () {

    final cells = {

      'Nº Entrega': '305557690',

      'NF/Série': '100535/85',

      'Nº Pedido': '171100173208601',

      'SPX TN': '305557690',

      'Endereço': 'RUA TESTE 100',

    };

    expect(importRomaneioTracking(cells), '305557690');

    expect(importRomaneioSequence(cells, 1), 1);

  });



  test('Relatório PDF — ID do Pacote (não código de barras longo)', () {

    final cells = {

      'ID do Pacote': '563608526',

      'Código de Barras': 'LG3COM4Q2UKXYJ3XZRYV',

      'SPX TN': '563608526',

      'Endereço Completo': 'Rua Apodi, 15',

    };

    expect(importRomaneioTracking(cells), '563608526');

    expect(importRomaneioSequence(cells, 3), 3);

  });



  test('Planilha com coluna Sequence explícita', () {

    final cells = {

      'Sequence': '42',

      'SPX TN': 'BR123',

    };

    expect(importRomaneioSequence(cells, 9), 42);

    expect(importRomaneioTracking(cells), 'BR123');

  });

  test('Magalog — prioriza Nº entrega; Loggi — ID da entrega', () {
    expect(
      importRomaneioTracking(
        {'ID da Entrega': 'LGG-1', 'Nº Entrega': '305111222'},
        carrier: RomaneioCarrier.magalog,
      ),
      '305111222',
    );
    expect(
      importRomaneioTracking(
        {'Nº Entrega': '305111222', 'ID da Entrega': 'LGG-99'},
        carrier: RomaneioCarrier.loggi,
      ),
      'LGG-99',
    );
  });

}



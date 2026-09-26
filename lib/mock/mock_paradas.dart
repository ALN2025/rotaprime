import 'package:rota_prime/models/parada.dart';
import 'package:rota_prime/utils/parada_packages.dart';
import 'package:rota_prime/utils/spx_regex.dart';

class MockParadas {
  static const _enderecos = [
    'Rua Romulo Domingos Dal Pozzo, 720, Fim da rua, Serrano',
    'Rua Anacleto Vidor (entregar somente para a Fernanda), Centro',
    'Rua Os Dezoito do Forte, 500, Serrano',
    'Rua Pinheiro Machado, 1200, Centro',
    'Rua Sinimbu, 800, Centro',
    'Rua Moreira Cesar, 450, Pio X',
    'Rua Dr. Montaury, 300, Exposição',
    'Rua Ernesto Alves, 150, Centro',
    'Rua Visconde de Pelotas, 900, Centro',
    'Rua Julio de Castilhos, 200, Centro',
  ];

  static const _spxCodes = [
    'BR269219586360G',
    'BR266047672043P',
    'BR265323512286J',
    'BR268812345678A',
    'BR267901234567B',
  ];

  static List<Parada> generate({required int rotaId, int count = 90}) {
    const baseLat = -29.1678;
    const baseLng = -51.1794;
    final list = <Parada>[];

    for (var i = 0; i < count; i++) {
      final addr = _enderecos[i % _enderecos.length];
      final spx = _spxCodes[i % _spxCodes.length];
      final bairro = addr.contains('Serrano')
          ? 'Serrano'
          : addr.contains('Centro')
              ? 'Centro'
              : 'Caxias do Sul';
      final raw =
          '-; -; $spx; $addr; $bairro; Caxias do Sul; -; ${baseLat + (i * 0.0003)}; ${baseLng + (i * 0.0004)}';

      list.add(Parada()
        ..rotaId = rotaId
        ..sequence = i + 1
        ..stop = i + 1
        ..spxTn = spx
        ..destinationAddress = addr
        ..bairro = bairro
        ..city = 'Caxias do Sul'
        ..zipcode = '95000-000'
        ..latitude = baseLat + (i * 0.00035)
        ..longitude = baseLng + (i * 0.00045)
        ..rawLine = raw
        ..ordemExibicao = i + 1
        ..quantidadePacotes = (i % 17 == 10) ? 2 : 1
        ..entregue = i < 12);
    }
    finalizePackageQtyFromImport(list);
    return list;
  }

  static List<Map<String, String>> previewRows() {
    return [
      {
        'AT ID': 'AT-001',
        'Sequence': '1',
        'Stop': '1',
        'SPX TN': 'BR269219586360G',
        'Destination Address': 'Rua Romulo Domingos Dal Pozzo, 720, Fim da rua',
        'Bairro': 'Serrano',
        'City': 'Caxias do Sul',
        'Zipcode': '95059-000',
        'Latitude': '-29.1678',
        'Longitude': '-51.1794',
      },
      {
        'AT ID': 'AT-002',
        'Sequence': '2',
        'Stop': '2',
        'SPX TN': 'BR266047672043P',
        'Destination Address': 'Rua Anacleto Vidor, Centro',
        'Bairro': 'Centro',
        'City': 'Caxias do Sul',
        'Zipcode': '95020-000',
        'Latitude': '-29.1685',
        'Longitude': '-51.1780',
      },
      {
        'AT ID': 'AT-003',
        'Sequence': '3',
        'Stop': '3',
        'SPX TN': 'BR265323512286J',
        'Destination Address': 'Rua Os Dezoito do Forte, 500',
        'Bairro': 'Serrano',
        'City': 'Caxias do Sul',
        'Zipcode': '95059-100',
        'Latitude': '-29.1690',
        'Longitude': '-51.1800',
      },
    ];
  }

  static String previewLine() =>
      'BR269219586360G; Rua Romulo Domingos Dal Pozzo, 720, Fim da rua; Serrano; Caxias do Sul;';

  static bool autoMarkField(String label, String sample) {
    final l = label.toLowerCase();
    if (l.contains('destination') || l.contains('address')) return true;
    if (l.contains('spx') || l.contains('tn')) return true;
    if (sample.trim().isNotEmpty) return true;
    return looksLikeTrackingCode(sample);
  }
}

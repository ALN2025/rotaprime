import 'package:isar_community/isar.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';
import 'package:rota_prime/models/romaneio_carrier.dart';

part 'parada.g.dart';

@collection
class Parada {
  Id id = Isar.autoIncrement;

  late int rotaId;

  int sequence = 0;
  int stop = 0;
  String spxTn = '';
  /// Prazo do romaneio (ex.: Loggi `23/09/2026 22:00`).
  String prazoEntrega = '';
  String destinationAddress = '';
  String bairro = '';
  String city = '';
  String zipcode = '';
  double? latitude;
  double? longitude;
  String rawLine = '';
  int ordemExibicao = 0;
  /// Pacotes nesta parada (coluna da planilha ou agrupamento por Stop).
  int quantidadePacotes = 1;
  bool entregue = false;
  bool falha = false;
  /// Definido na entrada manual ou heurística (pin empresa vs casa).
  bool entregaComercial = false;

  @enumerated
  ImportRomaneioLayout romaneioLayout = ImportRomaneioLayout.padrao;

  @enumerated
  RomaneioCarrier romaneioCarrier = RomaneioCarrier.generico;
}

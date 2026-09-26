import 'package:isar_community/isar.dart';
import 'package:rota_prime/models/import_romaneio_layout.dart';

part 'rota.g.dart';

enum RotaStatus { rascunho, ativa, finalizada }

@collection
class RotaRecord {
  Id id = Isar.autoIncrement;

  String titulo = 'Rota Caxias do Sul';
  String ownerEmail = '';
  @enumerated
  RotaStatus status = RotaStatus.rascunho;

  double kmInicial = 0;
  double? kmFinal;
  double valorPago = 280;

  int duracaoMinutos = 192;
  double distanciaKm = 43.4;
  bool otimizada = false;

  String? rotaGeometriaJson;
  double? origemLatitude;
  double? origemLongitude;
  DateTime criadaEm = DateTime.now();
  DateTime? finalizadaEm;

  /// Preenchido quando a rota nasceu de importação XLSX (romaneio).
  String? arquivoPlanilhaImportada;

  /// Totais na importação (denominador do progresso — ex.: 90 pacotes).
  int pacotesImportados = 0;
  int paradasImportadas = 0;

  @enumerated
  ImportRomaneioLayout romaneioLayout = ImportRomaneioLayout.padrao;
}

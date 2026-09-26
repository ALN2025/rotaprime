import 'package:isar_community/isar.dart';

part 'gasto.g.dart';

@collection
class Gasto {
  Id id = Isar.autoIncrement;

  late int rotaId;
  String tipo = 'Combustível';
  double valor = 0;
  String? fotoPath;
  DateTime criadoEm = DateTime.now();
}

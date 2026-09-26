import 'package:flutter/foundation.dart';

import 'package:isar_community/isar.dart';

import 'package:path_provider/path_provider.dart';

import 'package:rota_prime/models/gasto.dart';

import 'package:rota_prime/models/parada.dart';

import 'package:rota_prime/models/rota.dart';



class IsarService {

  static Isar? _isar;

  static Future<Isar>? _opening;



  static Future<Isar> get instance {

    if (_isar != null && _isar!.isOpen) {

      return Future.value(_isar!);

    }

    return _opening ??= _openOnce();

  }



  static Future<Isar> _openOnce() async {

    try {

      final dir = await getApplicationDocumentsDirectory();

      try {

        _isar = await Isar.open(

          [ParadaSchema, RotaRecordSchema, GastoSchema],

          directory: dir.path,

        );

      } catch (e, st) {

        if (kDebugMode) {

          debugPrint('Isar.open falhou, tentando banco alternativo: $e\n$st');

        }

        _isar = await Isar.open(

          [ParadaSchema, RotaRecordSchema, GastoSchema],

          directory: dir.path,

          name: 'rota_prime_v2',

        );

      }

      return _isar!;

    } catch (e, st) {

      _opening = null;

      if (kDebugMode) {

        debugPrint('Isar indisponível: $e\n$st');

      }

      rethrow;

    }

  }



  static Future<void> close() async {

    await _isar?.close();

    _isar = null;

    _opening = null;

  }

}


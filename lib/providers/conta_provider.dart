import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/models/rota.dart';
import 'package:rota_prime/providers/rota_provider.dart';

final contaRotasProvider = FutureProvider<List<RotaRecord>>((ref) async {
  ref.keepAlive();
  ref.watch(rotaProvider.select((s) => s.rota?.status));
  return ref.read(rotaProvider.notifier).loadRotasSalvas();
});

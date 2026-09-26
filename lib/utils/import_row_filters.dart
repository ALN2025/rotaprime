import 'package:rota_prime/utils/column_matcher.dart';



/// Extra: se a planilha tiver coluna Status (raro — a Shopee já costuma mandar só pendentes).
/// Linhas entregue/cancelado — não entram na rota.

bool shouldSkipRomaneioRow(Map<String, String> cells) {
  final isLoggi = (cells['Transportadora'] ?? '').toLowerCase() == 'loggi';

  final status = (pickCell(cells, deliveryStatusAliases) ?? '').toLowerCase().trim();

  if (status.isEmpty) {

    final deliveredFlag = (pickCell(cells, deliveredFlagAliases) ?? '').toLowerCase().trim();

    if (_isTruthyDelivered(deliveredFlag)) return true;

    return false;

  }

  for (final token in _skipStatusTokens) {
    if (isLoggi && token == 'retirad') continue;
    if (status.contains(token)) return true;
  }

  return false;

}



bool _isTruthyDelivered(String v) {

  if (v.isEmpty) return false;

  const yes = {'yes', 'y', 'sim', 's', '1', 'true', 'entregue', 'delivered', 'done'};

  return yes.contains(v);

}



const _skipStatusTokens = [

  'delivered',

  'entregue',

  'entreg',

  'completed',

  'complete',

  'conclu',

  'cancel',

  'cancelad',

  'failed',

  'falha',

  'returned',

  'devolv',

  'picked up',

  'retirad',

  'collected',

  'lost',

  'removed',

  'baixad',

];



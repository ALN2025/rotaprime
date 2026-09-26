import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

/// Itens da legenda do mapa (pins / paradas).
class MapLegendEntry {
  const MapLegendEntry({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;
}

const kDeliveryMapLegendEntries = [
  MapLegendEntry(
    color: Color(0xFF2196F3),
    title: 'Você (GPS)',
    description:
        'Seta/azul no mapa: sua posição agora. Com cadeado fechado o mapa não arrasta — só você e a linha laranja atualizam.',
  ),
  MapLegendEntry(
    color: AppColors.stopPending,
    title: 'Pendente',
    description:
        'Casa: um pin no endereço de cada imóvel. Condomínio/prédio: um pin por AP (vários no mapa em círculo). Vários pacotes no mesmo AP: número = quantidade. Toque no pin ou use a Lista.',
  ),
  MapLegendEntry(
    color: AppColors.orange,
    title: 'Parada em foco',
    description:
        'Pin laranja da entrega escolhida. A linha laranja no mapa liga o seu GPS a esse endereço (não é o ícone do carro).',
  ),
  MapLegendEntry(
    color: AppColors.successGreen,
    title: 'Entregue',
    description: 'Pacote marcado como entregue com sucesso neste endereço.',
  ),
  MapLegendEntry(
    color: AppColors.stopFailed,
    title: 'Não entregue',
    description: 'Tentativa registrada como não entregue (cliente ausente, endereço, etc.).',
  ),
];

/// Faixa vertical de cores — toque abre explicação completa.
class DeliveryMapLegend extends StatelessWidget {
  const DeliveryMapLegend({super.key, this.onTap});

  final VoidCallback? onTap;

  void _defaultTap(BuildContext context) => showDeliveryMapLegendSheet(context);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _defaultTap(context),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(height: 6),
              for (var i = 0; i < kDeliveryMapLegendEntries.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _LegendDotCompact(color: kDeliveryMapLegendEntries[i].color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDotCompact extends StatelessWidget {
  const _LegendDotCompact({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

/// Painel com significado de cada cor — fecha ao tocar em Fechar ou fora.
Future<void> showDeliveryMapLegendSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Legenda do mapa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cores dos pins e paradas na rota',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ...kDeliveryMapLegendEntries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: e.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

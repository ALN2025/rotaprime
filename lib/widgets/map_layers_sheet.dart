import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/app/map_basemap.dart';
import 'package:rota_prime/app/theme.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/widgets/spoke_widgets.dart';

Future<void> showMapLayersSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(mapSettingsProvider).basemap;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetDragHandle(),
                  const Text(
                    'Tipo de mapa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...MapBasemap.values.map((b) {
                    final selected = b == current;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? AppColors.orange : Colors.white38,
                      ),
                      title: Text(
                        b == MapBasemap.streets ? '${b.label} ★' : b.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: b == MapBasemap.streets ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        ref.read(mapSettingsProvider.notifier).setBasemap(b);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mapa: ${b.label}')),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

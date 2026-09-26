import 'package:flutter/material.dart';
import 'package:rota_prime/app/theme.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const libs = [
      ('Flutter SDK', 'BSD-3-Clause — Google'),
      ('Riverpod', 'MIT'),
      ('Isar Database', 'Apache-2.0'),
      ('file_picker', 'MIT'),
      ('flutter_map', 'BSD-3-Clause'),
      ('mobile_scanner', 'BSD-3-Clause'),
      ('geolocator', 'MIT'),
      ('intl', 'BSD-3-Clause'),
      ('http', 'BSD-3-Clause'),
      ('shared_preferences', 'BSD-3-Clause'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Licenças')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: libs.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
        itemBuilder: (context, i) {
          final (name, license) = libs[i];
          return ListTile(
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(license, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          );
        },
      ),
    );
  }
}

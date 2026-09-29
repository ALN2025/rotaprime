import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/subscription_provider.dart';

/// Consulta GitHub (trial liberado no script) sem botão manual: abertura, retorno ao app e intervalo.
class PlanPolicyAutoSync extends ConsumerStatefulWidget {
  const PlanPolicyAutoSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlanPolicyAutoSync> createState() => _PlanPolicyAutoSyncState();
}

class _PlanPolicyAutoSyncState extends ConsumerState<PlanPolicyAutoSync> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(force: true));
    });
    _timer = Timer.periodic(const Duration(seconds: 90), (_) {
      unawaited(_sync());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync(force: true));
    }
  }

  Future<void> _sync({bool force = false}) async {
    if (!mounted) return;
    await ref.read(subscriptionProvider.notifier).reloadPlanFromServer(force: force);
    if (!mounted) return;
    final sub = ref.read(subscriptionProvider);
    ref.read(mapSettingsProvider.notifier).syncBasemapWithPlan(sub);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(subscriptionProvider, (_, sub) {
      ref.read(mapSettingsProvider.notifier).syncBasemapWithPlan(sub);
    });
    return widget.child;
  }
}

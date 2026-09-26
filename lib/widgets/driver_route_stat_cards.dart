import 'package:flutter/material.dart';

import 'package:rota_prime/app/theme.dart';

import 'package:rota_prime/utils/route_time_labels.dart';



/// Cards de pacotes (com barra) e tempo na rota — estilo moderno sobre o mapa.

class DriverRouteStatCards extends StatelessWidget {

  const DriverRouteStatCards({

    super.key,

    required this.packagesDone,

    required this.packagesTotal,

    required this.routeActive,

    this.routeActiveSince,

    this.estimatedMinutes = 0,

  });



  final int packagesDone;

  final int packagesTotal;

  final bool routeActive;

  final DateTime? routeActiveSince;

  final int estimatedMinutes;



  @override

  Widget build(BuildContext context) {

    final total = packagesTotal > 0 ? packagesTotal : 1;

    final done = packagesDone.clamp(0, total);

    final progress = (done / total).clamp(0.0, 1.0);



    final timeMain = routeActive && routeActiveSince != null

        ? RouteTimeLabels.formatElapsed(DateTime.now().difference(routeActiveSince!))

        : (estimatedMinutes > 0

            ? RouteTimeLabels.formatMinutes(estimatedMinutes)

            : '—');

    final timeSub = routeActive ? 'tempo real' : 'estimado';



    return IntrinsicHeight(

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Expanded(

            child: _StatCard(

              icon: Icons.inventory_2_outlined,

              title: 'Pacotes',

              value: '$done / $total',

              subtitle: 'feitos',

              progress: progress,

              accent: AppColors.orange,

            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: _StatCard(

              icon: Icons.schedule_rounded,

              title: 'Na rota',

              value: timeMain,

              subtitle: timeSub,

              showProgress: false,

              accent: AppColors.successGreen,

            ),

          ),

        ],

      ),

    );

  }

}



class _StatCard extends StatelessWidget {

  const _StatCard({

    required this.icon,

    required this.title,

    required this.value,

    required this.subtitle,

    this.progress = 0,

    this.showProgress = true,

    required this.accent,

  });



  final IconData icon;

  final String title;

  final String value;

  final String subtitle;

  final double progress;

  final bool showProgress;

  final Color accent;



  @override

  Widget build(BuildContext context) {

    return DecoratedBox(

      decoration: BoxDecoration(

        color: Colors.black.withValues(alpha: 0.78),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.35),

            blurRadius: 12,

            offset: const Offset(0, 4),

          ),

        ],

      ),

      child: Padding(

        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Icon(icon, size: 14, color: accent),

                const SizedBox(width: 5),

                Text(

                  title,

                  style: TextStyle(

                    color: Colors.white.withValues(alpha: 0.78),

                    fontSize: 10,

                    fontWeight: FontWeight.w600,

                    letterSpacing: 0.2,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 6),

            FittedBox(

              fit: BoxFit.scaleDown,

              child: Text(

                value,

                textAlign: TextAlign.center,

                style: const TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.w800,

                  height: 1.1,

                  letterSpacing: -0.3,

                ),

              ),

            ),

            const SizedBox(height: 2),

            Text(

              subtitle,

              textAlign: TextAlign.center,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(

                color: Colors.white.withValues(alpha: 0.5),

                fontSize: 10,

                fontWeight: FontWeight.w500,

                height: 1.2,

              ),

            ),

            if (showProgress) ...[

              const SizedBox(height: 8),

              ClipRRect(

                borderRadius: BorderRadius.circular(3),

                child: LinearProgressIndicator(

                  value: progress,

                  minHeight: 4,

                  backgroundColor: Colors.white.withValues(alpha: 0.12),

                  color: accent,

                ),

              ),

            ],

          ],

        ),

      ),

    );

  }

}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/connectivity_controller.dart';
import '../theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityController>().offline;
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: offline ? top + 32 : 0,
      color: AppColors.warning,
      padding: EdgeInsets.only(top: top),
      child: offline
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 16, color: AppColors.headings),
                SizedBox(width: 8),
                Text(
                  'Offline — showing saved data',
                  style: TextStyle(
                    color: AppColors.headings,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

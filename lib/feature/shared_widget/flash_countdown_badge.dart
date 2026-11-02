import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/countdown_service.dart';

/// [F-1] Live countdown badge for flash deals.
/// Rebuilds ONLY this badge on each 1-second tick, leaving the rest of the screen untouched.
class FlashCountdownBadge extends StatelessWidget {
  final DateTime endsAt;
  final bool isCompact;
  final VoidCallback? onExpired; // Optional callback when countdown reaches zero

  const FlashCountdownBadge({
    super.key,
    required this.endsAt,
    this.isCompact = false,
    this.onExpired,
  });

  /// Format remaining duration into:
  /// - "hh:mm:ss" if 1 hour or more
  /// - "mm:ss" if less than 1 hour
  /// - "Expired" if 0 or negative
  static String formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      // 1 hour or more: hh:mm:ss
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } else {
      // Under 1 hour: mm:ss
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$m:$s';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the single heartbeat clock
    final ticker = Get.find<CountdownService>();

    // 2. Scoped reactivity: Obx wraps ONLY this badge, so parent widgets don't rebuild every second
    return Obx(() {
      final now = ticker.now.value;
      final remaining = endsAt.difference(now);
      final isExpired = remaining.isNegative || remaining.inSeconds <= 0;
      final text = formatRemaining(remaining);

      // Case A: Expired state -> Show grey "Expired" badge
      if (isExpired) {
        if (onExpired != null) {
          // Notify parent after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) => onExpired!());
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 6 : 8,
            vertical: isCompact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_disabled,
                size: isCompact ? 12 : 14,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 3),
              Text(
                'Expired',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }

      // Case B: Active state -> Show red badge with live countdown
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: isCompact ? 12 : 14,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                // Fixed-width digits prevent horizontal text shaking
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    });
  }
}

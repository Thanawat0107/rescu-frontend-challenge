import 'package:flutter/material.dart';
import 'package:get/get.dart';
// [F-1] Import live countdown badge
import 'package:rescu/feature/shared_widget/flash_countdown_badge.dart';

import '../../app_config.dart';
import '../../model/deal_model.dart';
import '../../routes/routes.dart';
import 'the_network_image.dart';

/// Deal card used in the home feed and search results.
class DealCard extends StatelessWidget {
  final DealModel deal;
  final String source;

  // [F-1] Observable boolean for expired state.
  // Rebuilds the card only ONCE when expired, not every second (prevents frame drops).
  final RxBool _isExpired;

  // [F-1] Non-const constructor to evaluate initial expiry state at runtime.
  DealCard({super.key, required this.deal, this.source = 'home'})
      : _isExpired = (deal.isFlashSale &&
                deal.flashSaleEndsAt != null &&
                deal.flashSaleEndsAt!.isBefore(DateTime.now()))
            .obs;

  @override
  Widget build(BuildContext context) {
    // [F-1] Obx listens ONLY to _isExpired (does NOT rebuild every second).
    return Obx(() {
      final isExpired = _isExpired.value;

      return Opacity(
        // [F-1] Dim card to 0.6 opacity when expired
        opacity: isExpired ? 0.6 : 1.0,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          elevation: 0.5,
          child: InkWell(
            // [F-1] Prevent opening expired deal for purchase
            onTap: isExpired
                ? () {
                    Get.snackbar(
                      'Deal Expired',
                      'This flash sale has ended and can no longer be ordered.',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  }
                : () => Get.toNamed(
                      Routes.dealRoute(deal.id, source: source),
                      arguments: deal,
                    ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    TheNetworkImage(
                        url: deal.imageUrl, height: 160, width: double.infinity),

                    // [F-1] Replaced static "FLASH SALE" text with live countdown badge
                    if (deal.isFlashSale && deal.flashSaleEndsAt != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: FlashCountdownBadge(
                          endsAt: deal.flashSaleEndsAt!,
                          // Triggers card rebuild only once when countdown hits zero
                          onExpired: () => _isExpired.value = true,
                        ),
                      ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${deal.quantityLeft} left',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(deal.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Pick up ${deal.pickupWindow.label}',
                              style: TextStyle(
                                  fontSize: 12.5, color: Colors.grey.shade700)),
                          const Spacer(),
                          if (deal.rating != null) ...[
                            const Icon(Icons.star_rounded,
                                size: 15, color: Colors.amber),
                            Text(deal.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12.5)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('฿${deal.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryGreen)),
                          const SizedBox(width: 6),
                          Text('฿${deal.originalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConfig.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('-${deal.discountPercent}%',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppConfig.primaryGreen)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

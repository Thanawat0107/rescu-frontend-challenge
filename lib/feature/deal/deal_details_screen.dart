import 'package:flutter/material.dart';
import 'package:get/get.dart';
// [F-1] Import live countdown badge
import 'package:rescu/feature/shared_widget/flash_countdown_badge.dart';

import '../../app_config.dart';
import '../shared_widget/the_network_image.dart';
import 'deal_details_controller.dart';

class DealDetailsScreen extends GetView<DealDetailsController> {
  const DealDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deal = controller.deal;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  TheNetworkImage(url: deal.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deal.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(deal.storeName,
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                  Text(deal.storeAddress,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('฿${deal.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                               fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.primaryGreen)),
                      const SizedBox(width: 8),
                      Text('฿${deal.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough)),
                      const Spacer(),

                      // [F-1] Live countdown badge on details screen
                      if (deal.isFlashSale && deal.flashSaleEndsAt != null) ...[
                        FlashCountdownBadge(
                          endsAt: deal.flashSaleEndsAt!,
                          onExpired: () => controller.isExpired.value = true,
                        ),
                        const SizedBox(width: 8),
                      ],

                      Obx(() => Chip(
                            avatar: const Icon(Icons.inventory_2_outlined,
                                size: 16),
                            label:
                                Text('${controller.quantityLeft ?? '-'} left'),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E5E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: AppConfig.primaryGreen),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pickup window',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            Text(
                              '${deal.pickupWindow.label}'
                              '${deal.pickupWindow.isToday ? ' · today' : ''}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (deal.pickupWindow.isOpenNow)
                          const Chip(
                            label: Text('Open now'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('What you get',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(deal.description,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade800)),
                  if (deal.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: deal.tags
                          .map((t) => Chip(
                                label: Text(t),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          // [F-1] Obx listens to controller.isExpired to disable the button when countdown reaches zero
          child: Obx(() {
            final isExpired = controller.isExpired.value;
            return FilledButton.icon(
              // When isExpired is true, onPressed becomes null (disables button)
              onPressed: isExpired ? null : controller.addToCart,
              icon: Icon(isExpired ? Icons.timer_off : Icons.add_shopping_cart),
              label: Text(isExpired ? 'Deal expired' : 'Add to bag'),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  // [F-1] Track whether this deal has expired
  final isExpired = false.obs;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  late final DealModel deal;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  @override
  void onInit() {
    super.onInit();
    deal = Get.arguments as DealModel;
    _quantityLeft.value = deal.quantityLeft;

    // [F-1] Check if already expired upon entering the screen
    if (deal.isFlashSale && deal.flashSaleEndsAt != null) {
      isExpired.value = deal.flashSaleEndsAt!.isBefore(DateTime.now());
    }

    analytics.logEvent('deal_details_view', {
      'deal_id': deal.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });

    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  Future<void> _recheckAvailability() async {
    LogService.log('re-checking availability for deal ${deal.id}');
    final fresh = await dealRepo.fetchById(deal.id);
    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    // [F-1] Guard check: prevent adding expired flash deals to cart
    if (isExpired.value) {
      Get.snackbar(
        'Deal expired',
        'This flash sale has ended and can no longer be ordered.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    cartService.add(deal);
    Get.snackbar(
      'Added to bag',
      '${deal.name} — pick up ${deal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}

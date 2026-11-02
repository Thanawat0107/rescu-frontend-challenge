import 'package:get/get.dart';
// [F-1] Import CountdownService to listen for clock ticks
import 'package:rescu/service/countdown_service.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // [F-1] Listen to the central 1-second clock tick to auto-reconcile expired flash deals
    final countdownService = Get.find<CountdownService>();
    ever(countdownService.now, (now) => _reconcileExpiredFlashDeals(now));
  }

  /// [F-1] Auto-remove expired flash deals from bag with visible user notification
  void _reconcileExpiredFlashDeals(DateTime now) {
    if (items.isEmpty) return;

    // Find any items in the bag whose flash sale countdown has reached zero
    final expiredItems = items
        .where((item) =>
            item.deal.isFlashSale &&
            item.deal.flashSaleEndsAt != null &&
            item.deal.flashSaleEndsAt!.isBefore(now))
        .toList();

    for (final item in expiredItems) {
      remove(item.deal.id); // Removes from cart and auto-recounts total

      // Show visible notice to user if UI overlay context is available
      if (Get.context != null) {
        Get.snackbar(
          'Flash Sale Ended',
          '${item.deal.name} has expired and was removed from your bag.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void add(DealModel deal) {
    // [F-1] Guard check: prevent adding an already-expired flash deal
    final countdown = Get.isRegistered<CountdownService>()
        ? Get.find<CountdownService>()
        : null;
    final currentTime = countdown?.now.value ?? DateTime.now();

    if (deal.isFlashSale &&
        deal.flashSaleEndsAt != null &&
        deal.flashSaleEndsAt!.isBefore(currentTime)) {
      if (Get.context != null) {
        Get.snackbar(
          'Deal Expired',
          'This flash sale has ended and can no longer be added to your bag.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return;
      }
      existing.quantity++;
      items.refresh();
    } else {
      items.add(CartItemModel(deal: deal));
    }
    _recount();
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      items.refresh();
    }
    _recount();
  }

  void remove(int dealId) {
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void clear() {
    items.clear();
    _recount();
  }

  num get total => items.fold(0, (sum, i) => sum + i.lineTotal);

  void _recount() {
    itemCount.value = items.fold(0, (sum, i) => sum + i.quantity);
  }
}

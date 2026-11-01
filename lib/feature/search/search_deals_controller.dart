import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  //variable private
  Timer? _debounceTimer;
  int _activeSearchId = 0;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _activeSearchId++;
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }

    // Debounce 500ms (0.5s for natural mobile typing cadence)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final searchId = ++_activeSearchId;
    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(query);
      // recheck response last search
      if (searchId == _activeSearchId) {
        results.assignAll(found);
      }
    } catch (e) {
      if (searchId == _activeSearchId) {
        LogService.error('search failed', e);
      }
    } finally {
      if (searchId == _activeSearchId) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}

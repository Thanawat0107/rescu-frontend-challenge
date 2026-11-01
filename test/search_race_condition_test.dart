import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/search/search_deals_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

/// 1. จำลอง DealRepo ขึ้นมาเองเพื่อดักจับและควบคุมการตอบกลับของ Network
class FakeDealRepo extends DealRepo {
  FakeDealRepo() : super(api: FakeApiService());

  Future<List<DealModel>> Function(String query)? onSearch;
  int searchCallCount = 0;
  final searchQueries = <String>[];

  @override
  Future<List<DealModel>> search(String query) async {
    searchCallCount++;
    searchQueries.add(query);
    if (onSearch != null) {
      return onSearch!(query);
    }
    return [];
  }
}

/// Helper สร้างข้อมูลจำลองของ DealModel
DealModel createTestDeal({required int id, required String name}) {
  return DealModel(
    id: id,
    name: name,
    description: 'Test deal description',
    imageUrl: 'https://example.com/test.jpg',
    originalPrice: 100,
    price: 50,
    currencyCode: 'THB',
    quantityLeft: 5,
    storeId: 1,
    storeName: 'Test Store',
    storeAddress: 'Bangkok',
    lat: 13.75,
    lng: 100.5,
    rating: 4.5,
    tags: const ['test'],
    pickupWindow: PickupWindowModel(
      start: DateTime(2026, 1, 1, 10, 0),
      end: DateTime(2026, 1, 1, 12, 0),
    ),
    flashSaleEndsAt: null,
  );
}

void main() {
  late FakeDealRepo fakeRepo;
  late SearchDealsController controller;

  setUp(() {
    fakeRepo = FakeDealRepo();
    controller = SearchDealsController(dealRepo: fakeRepo);
  });

  tearDown(() {
    controller.onClose();
  });

  group('[RES-101] Search Race Condition & Debounce Tests', () {
    // -------------------------------------------------------------
    // ข้อที่ 1: หัวใจสำคัญ! ทดสอบจำลอง Race Condition (ข้อมูลเก่าตอบมาช้ากว่า)
    // -------------------------------------------------------------
    test(
        '1. Ignores out-of-order response from earlier search (Race Condition)',
        () async {
      final completerS = Completer<List<DealModel>>();
      final completerSushi = Completer<List<DealModel>>();

      final dealS = [createTestDeal(id: 1, name: 'Sunrise Bakery')];
      final dealSushi = [createTestDeal(id: 2, name: 'Sushi Deluxe')];

      // เมื่อ controller เรียก search จะส่ง Completer กลับไปเพื่อให้เราสั่งตอบกลับเวลาไหนก็ได้
      fakeRepo.onSearch = (query) {
        if (query == 's') return completerS.future;
        if (query == 'sushi') return completerSushi.future;
        return Future.value([]);
      };

      // 1. ผู้ใช้พิมพ์ "s" -> รอพ้นระยะ debounce 500ms เพื่อให้ request ยิงออกไป
      controller.onQueryChanged('s');
      await Future.delayed(const Duration(milliseconds: 550));

      // 2. ผู้ใช้พิมพ์ "sushi" -> รอพ้นระยะ debounce 500ms เพื่อให้ request ยิงออกไป
      controller.onQueryChanged('sushi');
      await Future.delayed(const Duration(milliseconds: 550));

      // ตรวจสอบว่าระบบยิงออกไป 2 requests ตามลำดับ
      expect(fakeRepo.searchQueries, ['s', 'sushi']);

      // 3. จำลองสถานการณ์: "sushi" ตอบกลับมาถึงก่อน (Fast Response)
      completerSushi.complete(dealSushi);
      await Future.delayed(Duration.zero); // ให้ event loop ทำงาน

      // หน้าจอต้องแสดงผลของ "sushi"
      expect(controller.results.map((d) => d.name).toList(), ['Sushi Deluxe']);

      // 4. จำลองสถานการณ์: "s" เพิ่งตอบกลับมาถึงทีหลัง (Slow Out-of-order Response)
      completerS.complete(dealS);
      await Future.delayed(Duration.zero);

      // จุดวัดผลบั๊ก: หน้าจอต้องยังคงเป็น "sushi" อยู่! ไม่ถูก "s" มาเขียนทับ!
      expect(controller.results.map((d) => d.name).toList(), ['Sushi Deluxe']);
    });

    // -------------------------------------------------------------
    // ข้อที่ 2: ทดสอบว่า Debounce ทำงานจริง ยิง Request เดียวเมื่อพิมพ์รัวๆ
    // -------------------------------------------------------------
    test('2. Debounces rapid typing to a single request', () async {
      fakeRepo.onSearch = (query) async => [createTestDeal(id: 1, name: query)];

      // ผู้ใช้พิมพ์รัวๆ 5 ตัวอักษรติดกัน (ทุกๆ 50ms)
      controller.onQueryChanged('s');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.onQueryChanged('su');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.onQueryChanged('sus');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.onQueryChanged('sush');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.onQueryChanged('sushi');

      // รอจนเลย 500ms หลังตัวสุดท้าย
      await Future.delayed(const Duration(milliseconds: 550));

      // ต้องยิง Network ออกไปแค่ครั้งเดียว คือคำว่า 'sushi'
      expect(fakeRepo.searchCallCount, 1);
      expect(fakeRepo.searchQueries, ['sushi']);
    });

    // -------------------------------------------------------------
    // ข้อที่ 3: ทดสอบการลบคำค้นหาจนว่าง
    // -------------------------------------------------------------
    test('3. Clears results when query is empty', () async {
      controller.results.assignAll([createTestDeal(id: 1, name: 'Old Deal')]);
      controller.hasSearched.value = true;

      controller.onQueryChanged('   '); // เคาะช่องว่าง

      expect(controller.results, isEmpty);
      expect(controller.hasSearched.value, isFalse);
      expect(controller.isLoading.value, isFalse);
      expect(fakeRepo.searchCallCount, 0);
    });

    // -------------------------------------------------------------
    // ข้อที่ 4: ทดสอบการปิด Controller (onClose) ต้องยกเลิก Timer
    // -------------------------------------------------------------
    test('4. Cancels debounce timer on close', () async {
      controller.onQueryChanged('sushi');

      // ปิดหน้าจอทันทีก่อนครบ 500ms
      controller.onClose();

      await Future.delayed(const Duration(milliseconds: 550));

      // ต้องไม่ยิง request ตกค้าง
      expect(fakeRepo.searchCallCount, 0);
    });
  });
}

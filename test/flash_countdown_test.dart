import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/shared_widget/flash_countdown_badge.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/pickup_window_model.dart';
import 'package:rescu/service/cart_service.dart';
import 'package:rescu/service/countdown_service.dart';

/// Helper สำหรับสร้าง DealModel จำลองเพื่อใช้ในการทดสอบ
DealModel createFlashDeal({
  required int id,
  required String name,
  required DateTime endsAt,
  num originalPrice = 100,
  num price = 50,
}) {
  return DealModel(
    id: id,
    name: name,
    description: 'Flash deal for testing',
    imageUrl: 'https://example.com/test.jpg',
    originalPrice: originalPrice,
    price: price,
    currencyCode: 'THB',
    quantityLeft: 5,
    storeId: 1,
    storeName: 'Test Store',
    storeAddress: 'Bangkok',
    lat: 13.75,
    lng: 100.5,
    rating: 4.5,
    tags: const ['flash', 'food'],
    pickupWindow: PickupWindowModel(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(hours: 2)),
    ),
    flashSaleEndsAt: endsAt,
  );
}

void main() {
  group('[F-1] 1. FlashCountdownBadge.formatRemaining Unit Tests', () {
    test('คืนค่า "Expired" เมื่อเวลาหมด (Duration <= 0 หรือเป็นค่าลบ)', () {
      expect(
        FlashCountdownBadge.formatRemaining(const Duration(seconds: 0)),
        'Expired',
      );
      expect(
        FlashCountdownBadge.formatRemaining(const Duration(seconds: -10)),
        'Expired',
      );
      expect(
        FlashCountdownBadge.formatRemaining(const Duration(minutes: -1)),
        'Expired',
      );
    });

    test('จัดรูปแบบ mm:ss เมื่อเหลือเวลาไม่ถึง 1 ชั่วโมง (hours == 0)', () {
      // 45 วินาที -> 00:45
      expect(
        FlashCountdownBadge.formatRemaining(const Duration(seconds: 45)),
        '00:45',
      );
      // 5 นาที 9 วินาที -> 05:09 (ทดสอบการเติม 0 ด้านหน้า padLeft)
      expect(
        FlashCountdownBadge.formatRemaining(
          const Duration(minutes: 5, seconds: 9),
        ),
        '05:09',
      );
      // 59 นาที 59 วินาที -> 59:59
      expect(
        FlashCountdownBadge.formatRemaining(
          const Duration(minutes: 59, seconds: 59),
        ),
        '59:59',
      );
    });

    test('จัดรูปแบบ hh:mm:ss เมื่อเหลือเวลา 1 ชั่วโมงขึ้นไป (hours > 0)', () {
      // 1 ชั่วโมง 0 นาที 5 วินาที -> 01:00:05
      expect(
        FlashCountdownBadge.formatRemaining(
          const Duration(hours: 1, seconds: 5),
        ),
        '01:00:05',
      );
      // 2 ชั่วโมง 15 นาที 30 วินาที -> 02:15:30
      expect(
        FlashCountdownBadge.formatRemaining(
          const Duration(hours: 2, minutes: 15, seconds: 30),
        ),
        '02:15:30',
      );
      // 10 ชั่วโมง 0 นาที 0 วินาที -> 10:00:00
      expect(
        FlashCountdownBadge.formatRemaining(const Duration(hours: 10)),
        '10:00:00',
      );
    });
  });

  group('[F-1] 2. FlashCountdownBadge Widget Tests', () {
    late CountdownService countdownService;

    setUp(() {
      Get.reset(); // ล้าง GetX context ทุกครั้งก่อนเริ่มแต่ละเคส
      countdownService = Get.put(CountdownService());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets(
      'แสดงป้ายสีแดงพร้อมไอคอนสายฟ้าเมื่อยังมีเวลา และเปลี่ยนเป็น Expired สีเทาเมื่อหมดเวลา',
      (WidgetTester tester) async {
        final baseTime = DateTime(2026, 11, 2, 20, 0, 0);
        countdownService.now.value = baseTime;

        // กำหนดให้หมดอายุในอีก 5 วินาที
        final endsAt = baseTime.add(const Duration(seconds: 5));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlashCountdownBadge(endsAt: endsAt),
            ),
          ),
        );

        // 1. ตรวจสอบสถานะแรกเริ่ม: ต้องแสดง 00:05 และมีไอคอนสายฟ้า
        expect(find.text('00:05'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsOneWidget);
        expect(find.text('Expired'), findsNothing);

        // 2. จำลองเวลาเดินไป 2 วินาที (เหลือ 3 วินาที)
        countdownService.now.value = baseTime.add(const Duration(seconds: 2));
        await tester.pump();

        expect(find.text('00:03'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsOneWidget);

        // 3. จำลองเวลาเดินไปจนหมดเวลา (ผ่านไป 5 วินาที)
        countdownService.now.value = baseTime.add(const Duration(seconds: 5));
        await tester.pump();

        // ต้องเปลี่ยนเป็นป้าย Expired พร้อมไอคอนนาฬิกาทราย
        expect(find.text('Expired'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_disabled), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsNothing);
      },
    );
  });

  group('[F-1] 3. CartService Flash Sale Auto-Eviction Tests', () {
    late CountdownService countdownService;
    late CartService cartService;

    setUp(() {
      Get.reset();
      countdownService = Get.put(CountdownService());
      cartService = Get.put(CartService());
    });

    tearDown(() {
      Get.reset();
    });

    test('ดีดสินค้าที่หมดอายุออกจากตะกร้าอัตโนมัติเมื่อเวลาข้าม endsAt', () {
      final baseTime = DateTime(2026, 11, 2, 12, 0, 0);
      countdownService.now.value = baseTime;

      // สินค้า A: หมดอายุในอีก 10 นาที
      final activeDeal = createFlashDeal(
        id: 1,
        name: 'Sushi Set',
        endsAt: baseTime.add(const Duration(minutes: 10)),
        price: 80,
      );

      // สินค้า B: จะหมดอายุในอีก 5 วินาที
      final expiringDeal = createFlashDeal(
        id: 2,
        name: 'Bento Box',
        endsAt: baseTime.add(const Duration(seconds: 5)),
        price: 50,
      );

      // เพิ่มทั้งสองสินค้าลงตะกร้า
      cartService.add(activeDeal);
      cartService.add(expiringDeal);

      expect(cartService.itemCount.value, 2);
      expect(cartService.total, 130);

      // จำลองเวลาเดินข้ามไป 6 วินาที (สินค้า B หมดอายุ แต่สินค้า A ยังอยู่)
      countdownService.now.value = baseTime.add(const Duration(seconds: 6));

      // ตรวจสอบ: สินค้า B ต้องถูกลบออก เหลือเฉพาะสินค้า A
      expect(cartService.items.length, 1);
      expect(cartService.items.first.deal.id, 1);
      expect(cartService.items.first.deal.name, 'Sushi Set');
      expect(cartService.itemCount.value, 1);
      expect(cartService.total, 80); // ยอดรวมถูกคำนวณใหม่ถูกต้อง
    });

    test('ป้องกันไม่ให้เพิ่มสินค้าที่หมดอายุแล้วลงในตะกร้า', () {
      // ดีลนี้หมดอายุไปแล้วตั้งแต่ 1 ชั่วโมงที่แล้ว
      final pastDeal = createFlashDeal(
        id: 99,
        name: 'Old Pizza',
        endsAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      cartService.add(pastDeal);

      // ตะกร้าต้องว่างเปล่า
      expect(cartService.items.isEmpty, true);
      expect(cartService.itemCount.value, 0);
    });
  });
}


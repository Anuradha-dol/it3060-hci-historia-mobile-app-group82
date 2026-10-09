import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/booking/booking_models.dart';
import 'package:frontend/booking/booking_provider.dart';
import 'package:frontend/booking/booking_service.dart';
import 'package:frontend/booking/booking_flow_screen.dart';
import 'package:frontend/booking/booking_widgets.dart';

final guideFixture = BookableGuide({
  'id': 7,
  'name': 'Test guide',
  'languages': ['English'],
  'available': true,
  'packages': [
    {
      'id': 1,
      'name': 'Full Heritage Walk',
      'durationMinutes': 120,
      'pricePerVisitor': 2500,
      'minVisitors': 1,
      'maxVisitors': 5,
      'features': 'Guided walk · Offline meeting',
    },
    {
      'id': 2,
      'name': 'Point to Point',
      'durationMinutes': 45,
      'pricePerVisitor': 1500,
      'minVisitors': 1,
      'maxVisitors': 3,
      'features': 'Guide assistance',
    },
  ],
});
final landmarkFixture = Landmark({
  'id': 'clock',
  'name': 'Clock Tower Gate',
  'mapX': .6,
  'mapY': .3,
  'description': 'Entrance',
  'accessInfo': 'Ask your guide',
});
final slotFixture = DateTime.now()
    .toUtc()
    .add(const Duration(days: 1))
    .toIso8601String();

class FakeBookingService extends BookingService {
  int holds = 0;
  final keys = <String>[];
  bool fail = false;
  Completer<List<String>>? delayedSlots;
  @override
  Future<List<Landmark>> landmarks() async => [landmarkFixture];
  @override
  Future<List<String>> slots(int guide, int package, String date) =>
      delayedSlots?.future ?? Future.value([slotFixture]);
  @override
  Future<GuideReservation> hold(Json body) async {
    holds++;
    keys.add(body['requestKey']);
    await Future<void>.delayed(Duration.zero);
    if (fail) throw StateError('connection lost after submit');
    return GuideReservation({
      ...body,
      'id': 'test-booking',
      'reference': 'HS-TEST',
      'guideName': 'Test guide',
      'packageName': 'Full Heritage Walk',
      'landmark': landmarkFixture.json,
      'amount': 2500 * (body['visitors'] as int),
      'holdExpiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
      'state': 'HELD',
      'demoPaymentEnabled': true,
    });
  }

  @override
  Future<GuideReservation> state(String id, String state) async =>
      GuideReservation({'id': id, 'state': state});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'package pricing, capacity, preserved selections and payload schedule',
    () async {
      final service = FakeBookingService();
      final p = BookingProvider(service: service);
      await p.selectGuide(guideFixture);
      p.selectSlot(slotFixture);
      p.count(3);
      expect(p.subtotal, 7500);
      expect(p.visitors, 3);
      expect(p.meeting!.id, 'clock');
      expect(await p.createHold(), true);
      expect(p.reservation!.json['startsAt'], slotFixture);
      expect(await p.releaseHold(), true);
      expect(p.slot, slotFixture);
      expect(p.visitors, 3);
      await p.selectPackage(guideFixture.packages[1]);
      expect(p.subtotal, 4500);
      p.count(100);
      expect(p.visitors, 3);
      p.count(-1);
      expect(p.visitors, 1);
      p.dispose();
    },
  );
  test('double tap is blocked and retry preserves idempotency key', () async {
    final s = FakeBookingService();
    final p = BookingProvider(service: s);
    await p.selectGuide(guideFixture);
    p.selectSlot(slotFixture);
    s.fail = true;
    final first = p.createHold();
    expect(await p.createHold(), false);
    await first;
    s.fail = false;
    expect(await p.createHold(), true);
    expect(s.holds, 2);
    expect(s.keys[0], s.keys[1]);
    expect(await p.createHold(), true);
    expect(s.holds, 2);
    p.dispose();
  });
  test('out of order slot responses cannot overwrite newest date', () async {
    final s = FakeBookingService();
    final p = BookingProvider(service: s);
    await p.selectGuide(guideFixture);
    final slow = Completer<List<String>>();
    s.delayedSlots = slow;
    final earlier = p.selectDate(DateTime(2030, 1, 1));
    s.delayedSlots = null;
    await p.selectDate(DateTime(2030, 1, 2));
    slow.complete(['stale-response']);
    await earlier;
    expect(p.slots, [slotFixture]);
    expect(p.date.day, 2);
    p.dispose();
  });
  test(
    'offline cache is owner scoped, restores provisional match, clears on logout',
    () async {
      final b = GuideReservation({
        'id': 'b',
        'state': 'CONFIRMED',
        'meetingPin': '1234',
      });
      await BookingCache.save(10, [b]);
      await BookingCache.pending(10, 'b', '1234');
      expect((await BookingCache.read(10))['pending']['b'], '1234');
      expect(await BookingCache.read(20), isEmpty);
      expect((await BookingCache.read(10))['bookings'][0]['id'], 'b');
      await BookingCache.pending(10, 'b', null);
      expect((await BookingCache.read(10))['pending'], isEmpty);
      await BookingCache.clear();
      expect(await BookingCache.read(10), isEmpty);
    },
  );
  test(
    'stale location never yields a fresh countdown; PIN expires locally',
    () {
      final now = DateTime.now();
      final b = GuideReservation({
        'state': 'CONFIRMED',
        'meetingPin': '1234',
        'pinExpiresAt': now
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
        'locationUpdatedAt': now
            .subtract(const Duration(seconds: 40))
            .toIso8601String(),
        'eta': now.add(const Duration(minutes: 8)).toIso8601String(),
      });
      expect(b.stale, true);
      expect(b.countdown, 'ETA pending');
      expect(b.pinValid, false);
      final fresh = GuideReservation({
        ...b.json,
        'locationUpdatedAt': now.toIso8601String(),
      });
      expect(fresh.countdown, '08 MINS');
      expect(schedule('2026-10-08T05:00:00Z'), '2026-10-08  10:30 · Sri Lanka');
    },
  );
  for (final width in [360.0, 430.0]) {
    testWidgets(
      'customize, meeting and review fit at $width with retained selections',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final p = BookingProvider(service: FakeBookingService());
        await p.selectGuide(guideFixture);
        p.selectSlot(slotFixture);
        p.count(3);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: p,
            child: const MaterialApp(home: BookingFlowScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('LKR 7500'), findsOneWidget);
        await tester.ensureVisible(find.text('Review booking details'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Review booking details'));
        await tester.pumpAndSettle();
        expect(find.byType(MeetingMap), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('✓  Confirm Meeting Point'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('✓  Confirm Meeting Point'));
        await tester.pumpAndSettle();
        expect(p.error, isNull);
        expect(p.reservation, isNotNull);
        expect(find.text('Review & pay.'), findsOneWidget);
        expect(find.text('LKR 7500'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(p.visitors, 3);
        expect(p.slot, slotFixture);
        await tester.pumpWidget(const SizedBox());
        p.dispose();
      },
    );
  }
}

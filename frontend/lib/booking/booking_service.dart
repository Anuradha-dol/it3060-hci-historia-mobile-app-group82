import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'booking_models.dart';

class BookingService {
  final Dio dio;
  BookingService({Dio? dio}) : dio = dio ?? ApiService.instance.dio;
  static const path = '/api/guide-bookings';
  Future<List<BookableGuide>> guides(Json filters) async =>
      ((await dio.get('$path/guides', queryParameters: filters)).data as List)
          .map((j) => BookableGuide(Json.from(j)))
          .toList();
  Future<List<Landmark>> landmarks() async =>
      ((await dio.get('$path/landmarks')).data as List)
          .map((j) => Landmark(Json.from(j)))
          .toList();
  Future<List<String>> slots(int guide, int package, String date) async =>
      List<String>.from(
        (await dio.get(
          '$path/slots',
          queryParameters: {
            'guideId': guide,
            'packageId': package,
            'date': date,
          },
        )).data,
      );
  Future<GuideReservation> hold(Json body) async =>
      GuideReservation(Json.from((await dio.post(path, data: body)).data));
  Future<List<GuideReservation>> mine() async =>
      ((await dio.get(path)).data as List)
          .map((j) => GuideReservation(Json.from(j)))
          .toList();
  Future<GuideReservation> get(String id) async =>
      GuideReservation(Json.from((await dio.get('$path/$id')).data));
  Future<CheckoutContract> checkout(String id) async =>
      CheckoutContract(Json.from((await dio.get('$path/$id/checkout')).data));
  Future<GuideReservation> pay(String id, String outcome) async =>
      GuideReservation(
        Json.from(
          (await dio.post(
            '$path/$id/demo-checkout',
            data: {'outcome': outcome},
          )).data,
        ),
      );
  Future<GuideReservation> state(String id, String state) async =>
      GuideReservation(
        Json.from(
          (await dio.post('$path/$id/state', data: {'state': state})).data,
        ),
      );
  Future<GuideReservation> location(
    String id,
    double lat,
    double lon,
    DateTime? eta,
  ) async => GuideReservation(
    Json.from(
      (await dio.post(
        '$path/$id/location',
        data: {
          'latitude': lat,
          'longitude': lon,
          'eta': eta?.toUtc().toIso8601String(),
        },
      )).data,
    ),
  );
  Future<Json> pin(String id, String pin) async => Json.from(
    (await dio.post('$path/$id/verify-pin', data: {'pin': pin})).data,
  );
  Future<Json> management() async =>
      Json.from((await dio.get('$path/management')).data);
  Future<void> savePackage(Json data) async =>
      dio.put('$path/management/packages', data: data);
  Future<void> addWindow(Json data) async =>
      dio.post('$path/management/windows', data: data);
  Future<void> deleteWindow(int id) async =>
      dio.delete('$path/management/windows/$id');
}

class BookingCache {
  static const storage = FlutterSecureStorage();
  static const key = 'guide_booking_cache';
  static Future<void> _writes = Future.value();
  static int _generation = 0;
  static Future<void> _enqueue(Future<void> Function() work) {
    final next = _writes.then((_) => work());
    _writes = next.catchError((Object _) {});
    return next;
  }

  static Future<Json> read(int owner) async {
    final raw = await storage.read(key: key);
    if (raw == null) return {};
    final value = Json.from(jsonDecode(raw));
    return value['owner'] == owner ? value : {};
  }

  static Future<void> save(int owner, List<GuideReservation> bookings) {
    final generation = _generation;
    return _enqueue(() async {
      if (generation != _generation) return;
      final old = await read(owner);
      if (generation != _generation) return;
      await storage.write(
        key: key,
        value: jsonEncode({
          'owner': owner,
          'bookings': bookings.map((b) => b.json).toList(),
          'pending': old['pending'] ?? {},
        }),
      );
    });
  }

  static Future<void> pending(int owner, String id, String? pin) {
    final generation = _generation;
    return _enqueue(() async {
      if (generation != _generation) return;
      final old = await read(owner);
      if (generation != _generation) return;
      final pending = Json.from(old['pending'] ?? {});
      if (pin == null) {
        pending.remove(id);
      } else {
        pending[id] = pin;
      }
      old['owner'] = owner;
      old['pending'] = pending;
      await storage.write(key: key, value: jsonEncode(old));
    });
  }

  static Future<void> clear() {
    _generation++;
    return _enqueue(() => storage.delete(key: key));
  }
}

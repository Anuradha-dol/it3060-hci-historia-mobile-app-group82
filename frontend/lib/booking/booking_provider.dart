import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService service;
  BookingProvider({BookingService? service})
    : service = service ?? BookingService();
  BookableGuide? guide;
  TourPackage? package;
  DateTime date = colomboNow();
  String? slot;
  int visitors = 1;
  Landmark? meeting;
  List<Landmark> landmarks = [];
  List<String> slots = [];
  GuideReservation? reservation;
  String? error;
  bool busy = false;
  bool loadingSlots = false;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  int _slotRequest = 0;
  String _requestKey = '';
  num get subtotal => (package?.price ?? 0) * visitors;
  void changed() {
    reservation = null;
    _requestKey = '';
    notifyListeners();
  }

  Future<void> selectGuide(BookableGuide g) async {
    guide = g;
    package = g.packages.isEmpty ? null : g.packages.first;
    visitors = package?.min ?? 1;
    slot = null;
    changed();
    try {
      landmarks = await service.landmarks();
      meeting = landmarks.isEmpty ? null : landmarks.first;
    } catch (e) {
      error = ApiService.instance.getErrorMessage(e);
    }
    await loadSlots();
  }

  Future<void> selectPackage(TourPackage p) async {
    package = p;
    visitors = visitors.clamp(p.min, p.max);
    changed();
    await loadSlots();
  }

  Future<void> selectDate(DateTime d) async {
    date = d;
    changed();
    await loadSlots();
  }

  void selectSlot(String s) {
    slot = s;
    changed();
  }

  void count(int n) {
    visitors = n.clamp(package!.min, package!.max);
    changed();
  }

  void selectMeeting(Landmark l) {
    meeting = l;
    changed();
  }

  Future<void> loadSlots() async {
    final request = ++_slotRequest;
    if (guide == null || package == null) return;
    loadingSlots = true;
    error = null;
    notifyListeners();
    try {
      if (landmarks.isEmpty) {
        landmarks = await service.landmarks();
        meeting = landmarks.isEmpty ? null : landmarks.first;
      }
      final result = await service.slots(guide!.id, package!.id, dateKey(date));
      if (request != _slotRequest) return;
      slots = result;
      if (!slots.contains(slot)) slot = null;
    } catch (e) {
      if (request == _slotRequest) {
        slots = [];
        slot = null;
        error = ApiService.instance.getErrorMessage(e);
      }
    } finally {
      if (request == _slotRequest) {
        loadingSlots = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createHold() async {
    if (busy || slot == null || meeting == null || package == null) {
      return false;
    }
    if (reservation != null && reservation!.state == 'HELD') return true;
    busy = true;
    error = null;
    notifyListeners();
    if (_requestKey.isEmpty) {
      _requestKey = List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    try {
      reservation = await service.hold({
        'guideId': guide!.id,
        'packageId': package!.id,
        'landmarkId': meeting!.id,
        'startsAt': slot,
        'visitors': visitors,
        'requestKey': _requestKey,
      });
      if (reservation!.state != 'HELD') {
        error =
            'This hold expired. Return to the schedule and select a time again.';
        return false;
      }
      return true;
    } catch (e) {
      error = ApiService.instance.getErrorMessage(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> releaseHold() async {
    if (reservation?.state != 'HELD') return true;
    try {
      await service.state(reservation!.id, 'CANCELLED');
      changed();
      return true;
    } catch (e) {
      error = ApiService.instance.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}

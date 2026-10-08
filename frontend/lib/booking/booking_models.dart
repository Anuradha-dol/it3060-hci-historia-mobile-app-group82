typedef Json = Map<String, dynamic>;

DateTime colomboNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String schedule(String value) {
  final d = DateTime.parse(
    value,
  ).toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${dateKey(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} · Sri Lanka';
}

String money(num value) =>
    'LKR ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

class TourPackage {
  final Json json;
  TourPackage(this.json);
  int get id => json['id'];
  String get name => json['name'];
  String get features => json['features'] ?? '';
  int get minutes => json['durationMinutes'];
  num get price => json['pricePerVisitor'];
  int get min => json['minVisitors'];
  int get max => json['maxVisitors'];
}

class BookableGuide {
  final Json json;
  BookableGuide(this.json);
  int get id => json['id'];
  String get name => json['name'];
  List<TourPackage> get packages =>
      (json['packages'] as List).map((p) => TourPackage(Json.from(p))).toList();
  List<String> get languages => List<String>.from(json['languages']);
  bool get available => json['available'] == true;
}

class Landmark {
  final Json json;
  Landmark(this.json);
  String get id => json['id'];
  String get name => json['name'];
  String get description => json['description'] ?? '';
  String get access => json['accessInfo'] ?? '';
  double get x => (json['mapX'] as num).toDouble();
  double get y => (json['mapY'] as num).toDouble();
}

class GuideReservation {
  final Json json;
  GuideReservation(this.json);
  String get id => json['id'];
  String get state => json['state'];
  String get reference => json['reference'];
  String get guide => json['guideName'];
  Landmark get landmark => Landmark(Json.from(json['landmark']));
  bool get active =>
      ['CONFIRMED', 'EN_ROUTE', 'ARRIVED', 'IN_PROGRESS'].contains(state);
  bool get stale =>
      json['locationUpdatedAt'] == null ||
      DateTime.now()
              .toUtc()
              .difference(DateTime.parse(json['locationUpdatedAt']))
              .inSeconds >
          30;
  bool get pinValid =>
      active &&
      json['meetingPin'] != null &&
      DateTime.parse(json['pinExpiresAt']).isAfter(DateTime.now());
  String get countdown {
    if (stale || json['eta'] == null) return 'ETA pending';
    final seconds = DateTime.parse(
      json['eta'],
    ).difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return 'ETA reached';
    return '${(seconds / 60).ceil().toString().padLeft(2, '0')} MINS';
  }
}

class CheckoutContract {
  final Json json;
  CheckoutContract(this.json);
  String get bookingId => json['bookingId'];
  num get amount => json['amount'];
  String get currency => json['currency'];
  bool get demoEnabled => json['demoEnabled'] == true;
}

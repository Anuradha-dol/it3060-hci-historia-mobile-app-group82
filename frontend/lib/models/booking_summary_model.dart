/// Summary of a confirmed guide booking that is ready for checkout.
///
/// The full booking/scheduling flow itself is owned by another module.
/// Instances are normally created from the backend's
/// `BookingCheckoutResponse` via [BookingSummary.fromJson].
/// [BookingSummary.sample] remains as a placeholder for previews/tests.
class BookingSummary {
  final int? id;
  final String guideName;
  final DateTime date;
  final int placesCount;
  final Duration duration;
  final double amount;
  final String currency;
  final String status;
  final bool reviewed;

  const BookingSummary({
    this.id,
    required this.guideName,
    required this.date,
    required this.placesCount,
    required this.duration,
    required this.amount,
    this.currency = 'LKR',
    this.status = 'PENDING',
    this.reviewed = false,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      id: (json['id'] as num?)?.toInt(),
      guideName: json['guideName']?.toString() ?? '',
      date: DateTime.parse(json['tourDate'].toString()),
      placesCount: (json['placesCount'] as num?)?.toInt() ?? 0,
      duration: Duration(
        minutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'LKR',
      status: json['status']?.toString() ?? 'PENDING',
      reviewed: json['reviewed'] as bool? ?? false,
    );
  }

  bool get isPaid => status == 'PAID';

  factory BookingSummary.sample() {
    return BookingSummary(
      guideName: 'Kandy Heritage Walk',
      date: DateTime(2026, 10, 12),
      placesCount: 4,
      duration: const Duration(hours: 1, minutes: 15),
      amount: 4500,
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get dateLabel => '${date.day} ${_months[date.month - 1]} ${date.year}';

  String get durationLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours <= 0) {
      return '$minutes min';
    }

    if (minutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $minutes min';
  }

  String get amountLabel => '$currency ${amount.toStringAsFixed(0)}';
}

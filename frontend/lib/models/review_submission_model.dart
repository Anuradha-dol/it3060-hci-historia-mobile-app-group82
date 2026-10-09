/// A tourist's rating and review for a completed guided tour.
class ReviewSubmission {
  final int bookingId;
  final int navigationRating;
  final int informationRating;
  final int facilitiesRating;
  final String comment;
  final int photoCount;

  const ReviewSubmission({
    required this.bookingId,
    required this.navigationRating,
    required this.informationRating,
    required this.facilitiesRating,
    this.comment = '',
    this.photoCount = 0,
  });

  double get averageRating =>
      (navigationRating + informationRating + facilitiesRating) / 3;
}

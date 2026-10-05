import 'package:flutter/material.dart';

import '../models/historical_place_model.dart';

class HistoricalPlaceDetailsScreen extends StatefulWidget {
  final HistoricalPlaceModel place;

  const HistoricalPlaceDetailsScreen({
    super.key,
    required this.place,
  });

  @override
  State<HistoricalPlaceDetailsScreen> createState() =>
      _HistoricalPlaceDetailsScreenState();
}

class _HistoricalPlaceDetailsScreenState
    extends State<HistoricalPlaceDetailsScreen> {
  static const Color primaryGreen = Color(0xFF14764C);
  static const Color darkGreen = Color(0xFF154E39);
  static const Color lightGreen = Color(0xFFF0F7F2);

  bool _isFavorite = false;
  bool _showFullDescription = false;

  HistoricalPlaceModel get place => widget.place;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context),

                    _buildAbout(),

                    _buildInformation(),

                    _buildLocationSection(),

                    _buildGallery(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 370,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMainImage(),

          // Dark gradient for readable text.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [
                  0.0,
                  0.45,
                  1.0,
                ],
                colors: [
                  Color(0x15000000),
                  Color(0x10000000),
                  Color(0xD9000000),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: _roundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Favorite
          Positioned(
            top: 16,
            right: 66,
            child: _roundButton(
              icon: _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: _isFavorite
                  ? Colors.redAccent
                  : darkGreen,
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(
                      milliseconds: 1000,
                    ),
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      _isFavorite
                          ? '${place.name} added to favorites.'
                          : '${place.name} removed from favorites.',
                    ),
                  ),
                );
              },
            ),
          ),

          // Share
          Positioned(
            top: 16,
            right: 16,
            child: _roundButton(
              icon: Icons.share_outlined,
              onTap: () {
                _showFeatureMessage(
                  'Sharing will be available soon.',
                );
              },
            ),
          ),

          // Main place information
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 18,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        _displayLocation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 21,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      _ratingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (place.openingHours.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 17,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          place.openingHours,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN IMAGE
  // ============================================================

  Widget _buildMainImage() {
    final String imagePath =
        place.mainImageUrl?.trim() ?? '';

    if (_isNetworkImage(imagePath)) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildLocalOrFallbackImage(
            place.name,
          );
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildLocalOrFallbackImage(
            place.name,
          );
        },
      );
    }

    return _buildLocalOrFallbackImage(
      place.name,
    );
  }

  Widget _buildLocalOrFallbackImage(
    String placeName,
  ) {
    final localAsset = _localImageForPlace(
      placeName,
    );

    if (localAsset != null) {
      return Image.asset(
        localAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _imagePlaceholder();
        },
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFDCEAE1),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: primaryGreen,
          ),

          SizedBox(height: 10),

          Text(
            'Historical Place',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP ROUND BUTTON
  // ============================================================

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = darkGreen,
  }) {
    return Material(
      color: Colors.white.withValues(
        alpha: 0.93,
      ),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAbout() {
    final description = place.description.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24352D),
            ),
          ),

          const SizedBox(height: 10),

          if (description.isEmpty)
            const Text(
              'Historical information is not available yet.',
              style: TextStyle(
                color: Color(0xFF7D8580),
                fontSize: 14,
                height: 1.5,
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(
                milliseconds: 200,
              ),
              child: Text(
                description,
                maxLines:
                    _showFullDescription ? null : 4,
                overflow: _showFullDescription
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D746F),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),

          if (description.length > 150) ...[
            const SizedBox(height: 7),

            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _showFullDescription =
                      !_showFullDescription;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showFullDescription
                          ? 'Show Less'
                          : 'Read More',
                      style: const TextStyle(
                        color: Color(0xFF287C43),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(width: 3),

                    Icon(
                      _showFullDescription
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(
                        0xFF287C43,
                      ),
                      size: 21,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARDS
  // ============================================================

  Widget _buildInformation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        18,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _infoCard(
              Icons.confirmation_number_outlined,
              'Entrance Fee',
              _entranceFeeText,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _infoCard(
              Icons.schedule_outlined,
              'Opening Hours',
              place.openingHours.isEmpty
                  ? 'Not available'
                  : place.openingHours,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _infoCard(
              Icons.near_me_outlined,
              'Location',
              _displayLocation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 128,
      ),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1EEE5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: primaryGreen,
              size: 22,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF777F79),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34473D),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION / GPS READY SECTION
  // ============================================================

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        22,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF9),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFDDEAE2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4EB),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.location_on_rounded,
                color: primaryGreen,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _displayLocation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B837E),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),

                  if (place.hasCoordinates) ...[
                    const SizedBox(height: 3),

                    Text(
                      '${place.latitude!.toStringAsFixed(4)}, '
                      '${place.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Color(0xFFA0A6A2),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _onDirectionsPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons.directions_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallery() {
    final gallery = _galleryImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Row(
            children: [
              const Text(
                'Gallery',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF24352D),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  _showFeatureMessage(
                    'More gallery images can be connected to the backend later.',
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF68746D),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        SizedBox(
          height: 115,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: gallery.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _buildGalleryImage(
                gallery[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryImage(String imagePath) {
    Widget image;

    if (_isNetworkImage(imagePath)) {
      image = Image.network(
        imagePath,
        width: 125,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _galleryPlaceholder();
        },
      );
    } else {
      image = Image.asset(
        imagePath,
        width: 125,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _galleryPlaceholder();
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: image,
    );
  }

  Widget _galleryPlaceholder() {
    return Container(
      width: 125,
      height: 110,
      color: const Color(0xFFE7EFEA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: primaryGreen,
        size: 30,
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          18,
          11,
          18,
          13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.04,
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onAddToTourPressed,
                icon: const Icon(
                  Icons.map_outlined,
                  size: 20,
                ),
                label: const Text(
                  'Add to Tour',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(
                    color: primaryGreen,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onCreatePostPressed,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 21,
                ),
                label: const Text(
                  'Create Post',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF08733E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON ACTIONS
  // ============================================================

  void _onDirectionsPressed() {
    if (!place.hasCoordinates) {
      _showFeatureMessage(
        'Location coordinates are not available for ${place.name}.',
      );
      return;
    }

    // GPS / external map navigation will be connected
    // in the location-service step.
    _showFeatureMessage(
      'Directions are ready to use '
      '${place.latitude!.toStringAsFixed(4)}, '
      '${place.longitude!.toStringAsFixed(4)}. '
      'We will connect map navigation next.',
    );
  }

  void _onAddToTourPressed() {
    _showFeatureMessage(
      '${place.name} can be added to the Tour Planner in the next integration step.',
    );
  }

  void _onCreatePostPressed() {
    _showFeatureMessage(
      'Create Post will open with ${place.name} selected when we connect the post flow.',
    );
  }

  void _showFeatureMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  String get _displayLocation {
    final location = place.location.trim();

    if (location.isEmpty) {
      return 'Location not available';
    }

    return location;
  }

  String get _ratingText {
    if (place.rating <= 0) {
      return 'Not rated yet';
    }

    return place.rating.toStringAsFixed(1);
  }

  String get _entranceFeeText {
    if (place.entranceFee <= 0) {
      return 'Free';
    }

    final double fee = place.entranceFee;

    if (fee == fee.roundToDouble()) {
      return 'Rs. ${fee.toInt()}';
    }

    return 'Rs. ${fee.toStringAsFixed(2)}';
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  // ============================================================
  // LOCAL IMAGE FALLBACK
  //
  // Database data remains dynamic.
  // These are only temporary UI image fallbacks for the images
  // already included in your Flutter project.
  // ============================================================

  String? _localImageForPlace(
    String placeName,
  ) {
    switch (placeName.toLowerCase().trim()) {
      case 'sigiriya':
        return 'assets/images/sigiriya.jpg';

      case 'ruwanwelisaya':
      case 'ruwanweli saya':
      case 'ruwanweli maha seya':
        return 'assets/images/ruwanwelisaya.jpg';

      case 'sri maha bodhi':
      case 'jaya sri maha bodhi':
        return 'assets/images/sri_maha_bodhi.jpg';

      case 'galle fort':
        return 'assets/images/galle_fort.jpg';

      case 'abhayagiri':
      case 'abhayagiri stupa':
      case 'abhayagiri dagoba':
        return 'assets/images/abhayagiri.jpg';

      default:
        return null;
    }
  }

  List<String> get _galleryImages {
    final String normalized =
        place.name.toLowerCase().trim();

    if (normalized == 'sigiriya') {
      return const [
        'assets/images/sigiriya_gallery_1.jpg',
        'assets/images/sigiriya_gallery_2.jpg',
        'assets/images/sigiriya_gallery_3.jpg',
      ];
    }

    final localMainImage =
        _localImageForPlace(place.name);

    final backendMainImage =
        place.mainImageUrl?.trim() ?? '';

    if (backendMainImage.isNotEmpty) {
      return [
        backendMainImage,
      ];
    }

    if (localMainImage != null) {
      return [
        localMainImage,
      ];
    }

    // This intentionally returns an invalid asset name.
    // _buildGalleryImage catches it and displays the
    // clean image placeholder.
    return const [
      'assets/images/historical_place_placeholder.jpg',
    ];
  }
}
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/historical_place_model.dart';
import '../services/api_service.dart';
import '../services/historical_place_service.dart';
import 'historical_place_details_screen.dart';

class HistoricalSearchScreen extends StatefulWidget {
  const HistoricalSearchScreen({super.key});

  @override
  State<HistoricalSearchScreen> createState() => _HistoricalSearchScreenState();
}

class _HistoricalSearchScreenState extends State<HistoricalSearchScreen> {
  static const Color primaryGreen = Color(0xFF19784E);
  static const Color darkGreen = Color(0xFF204F3E);
  static const Color background = Color(0xFFFAFCFA);

  final TextEditingController _searchController = TextEditingController();

  final HistoricalPlaceService _placeService = HistoricalPlaceService();

  String selectedTab = 'All';
  String searchQuery = '';

  List<HistoricalPlaceModel> _places = [];

  bool _loading = true;
  String? _error;

  Timer? _debounce;

  // Prevent an older request from replacing a newer search result.
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    _loadAllPlaces();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BACKEND DATA
  // ============================================================

  Future<void> _loadAllPlaces() async {
    final int requestVersion = ++_requestVersion;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _placeService.getAllPlaces();

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _places = [];
        _loading = false;
        _error = _getReadableError(error);
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      await _loadAllPlaces();
      return;
    }

    final int requestVersion = ++_requestVersion;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _placeService.searchPlaces(trimmedQuery);

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _places = [];
        _loading = false;
        _error = _getReadableError(error);
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _searchPlaces(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();

    _searchController.clear();

    setState(() {
      searchQuery = '';
    });

    _loadAllPlaces();
  }

  Future<void> _refresh() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      await _loadAllPlaces();
    } else {
      await _searchPlaces(query);
    }
  }

  String _getReadableError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        return 'Your session has expired. Please sign in again.';
      }

      if (statusCode == 403) {
        return 'You do not have permission to view historical places.';
      }

      if (statusCode == 404) {
        return 'Historical place service was not found.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'The server is temporarily unavailable. Please try again.';
      }
    }

    final message = ApiService.instance.getErrorMessage(error);

    if (message.isNotEmpty && message != 'Something went wrong.') {
      return message;
    }

    return 'Could not load historical places. Check that the backend is running and try again.';
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  Future<void> _openPlace(HistoricalPlaceModel place) async {
    try {
      final latestPlace = await _placeService.getPlaceById(place.id);

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoricalPlaceDetailsScreen(place: latestPlace),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getReadableError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: RefreshIndicator(
                color: primaryGreen,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _buildSearchBar(),

                    _buildTabs(),

                    const SizedBox(height: 24),

                    if (selectedTab == 'All' || selectedTab == 'Places')
                      _buildPlacesSection(),

                    if (!_loading &&
                        _error == null &&
                        _places.isNotEmpty &&
                        (selectedTab == 'All' || selectedTab == 'Posts'))
                      _buildPosts(),

                    if (!_loading &&
                        _error == null &&
                        _places.isNotEmpty &&
                        (selectedTab == 'All' || selectedTab == 'People'))
                      _buildPeople(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 20, 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 22,
                color: Color(0xFF154F3A),
              ),
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'Search',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF174E3B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        textInputAction: TextInputAction.search,

        onChanged: _onSearchChanged,

        onSubmitted: (value) {
          _debounce?.cancel();
          _searchPlaces(value);
        },

        decoration: InputDecoration(
          hintText: 'Search historical places',

          hintStyle: const TextStyle(color: Color(0xFF7D8580), fontSize: 15),

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1C312A),
            size: 26,
          ),

          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                  icon: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFFC5CBC7),
                    child: Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                )
              : null,

          filled: true,
          fillColor: const Color(0xFFF7F9F7),

          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFC8DDD0)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    const tabs = ['All', 'Places', 'Posts', 'People'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EAE6))),
      ),

      child: Row(
        children: tabs.map((tab) {
          final selected = selectedTab == tab;

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  border: selected
                      ? const Border(
                          bottom: BorderSide(color: primaryGreen, width: 3),
                        )
                      : null,
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? primaryGreen : const Color(0xFF7A817D),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // HISTORICAL PLACES SECTION
  // ============================================================

  Widget _buildPlacesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historical Places',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ),

              if (!_loading && _error == null && _places.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_places.length}',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 15),

          if (_loading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_places.isEmpty)
            _buildEmptyState()
          else
            ..._places.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: _buildPlaceCard(place),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PLACE CARD
  // ============================================================

  Widget _buildPlaceCard(HistoricalPlaceModel place) {
    return Material(
      color: const Color(0xFFF5FBF7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _openPlace(place);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFAAD8BD)),
          ),
          child: Row(
            children: [
              _buildPlaceImage(place, width: 112, height: 112, radius: 13),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF154D39),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 17,
                          color: primaryGreen,
                        ),

                        const SizedBox(width: 4),

                        Expanded(
                          child: Text(
                            place.location.isEmpty
                                ? 'Location unavailable'
                                : place.location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: Color(0xFF737B76),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107),
                          size: 20,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          place.rating > 0
                              ? place.rating.toStringAsFixed(1)
                              : 'Not rated',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF59625D),
                          ),
                        ),
                      ],
                    ),

                    if (place.openingHours.isNotEmpty) ...[
                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFF748079),
                            size: 15,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              place.openingHours,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF748079),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                size: 27,
                color: Color(0xFF174D3A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE HANDLING
  // ============================================================

  Widget _buildPlaceImage(
    HistoricalPlaceModel place, {
    required double width,
    required double height,
    required double radius,
  }) {
    final String imagePath = place.mainImageUrl?.trim() ?? '';

    Widget image;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      image = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildFallbackImage(place, width, height);
        },
      );
    } else if (imagePath.startsWith('assets/')) {
      String correctedPath = imagePath;

      if (imagePath.startsWith('assets/') &&
          !imagePath.startsWith('assets/images/')) {
        correctedPath = imagePath.replaceFirst('assets/', 'assets/images/');
      }

      image = Image.asset(
        correctedPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildFallbackImage(place, width, height);
        },
      );
    } else {
      image = _buildFallbackImage(place, width, height);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }

  Widget _buildFallbackImage(
    HistoricalPlaceModel place,
    double width,
    double height,
  ) {
    final fallbackAsset = _localImageForPlace(place.name);

    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildImagePlaceholder(width, height);
        },
      );
    }

    return _buildImagePlaceholder(width, height);
  }

  Widget _buildImagePlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE7EFEA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.account_balance_outlined,
        color: primaryGreen,
        size: 32,
      ),
    );
  }

  String? _localImageForPlace(String placeName) {
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

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: const Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 3,
            ),
          ),

          SizedBox(height: 15),

          Text(
            'Loading historical places...',
            style: TextStyle(color: Color(0xFF6F7C75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DDD5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFFB67861),
          ),

          const SizedBox(height: 14),

          const Text(
            'Unable to load places',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4D433F),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF817772),
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY SEARCH RESULT
  // ============================================================

  Widget _buildEmptyState() {
    final bool searching = searchQuery.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 58,
            color: Color(0xFF9CB8A8),
          ),

          const SizedBox(height: 15),

          Text(
            searching
                ? 'No historical places found'
                : 'No historical places available',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF315846),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            searching
                ? 'No registered historical place matches "$searchQuery".'
                : 'Historical places will appear here when they are added to HISTORIA.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7C8781),
              height: 1.5,
              fontSize: 12,
            ),
          ),

          if (searching) ...[
            const SizedBox(height: 17),

            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Clear Search'),
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // POSTS
  //
  // These are UI preview cards for the community section.
  // Historical-place search itself is now backend-driven.
  // ============================================================

  Widget _buildPosts() {
    final HistoricalPlaceModel place = _places.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 'Posts';
                  });
                },
                child: const Text(
                  'See all',
                  style: TextStyle(color: Color(0xFF747E78), fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          _buildPostCard(
            place,
            'Exploring ${place.name} ✨',
            'A beautiful historical experience in Sri Lanka.',
          ),

          const SizedBox(height: 9),

          _buildPostCard(
            place,
            '${place.name} – A Must Visit!',
            'History, culture and unforgettable memories.',
          ),

          const SizedBox(height: 9),

          _buildPostCard(
            place,
            'My ${place.name} Adventure',
            'Another amazing heritage journey. 💚',
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    HistoricalPlaceModel place,
    String title,
    String subtitle,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openPlace(place);
        },
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E5E1)),
          ),
          child: Row(
            children: [
              _buildPlaceImage(place, width: 86, height: 78, radius: 11),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF214E3E),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF808681),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 7,
                          backgroundColor: Color(0xFFE5EEE8),
                          child: Icon(
                            Icons.person,
                            size: 9,
                            color: primaryGreen,
                          ),
                        ),

                        SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            '@travelwithsara • 2 days ago',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF9AA09C),
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Color(0xFFA7B0AA)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PEOPLE
  //
  // This stays as presentation UI until your community/user
  // search backend is connected separately.
  // ============================================================

  Widget _buildPeople() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'People',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 'People';
                  });
                },
                child: const Text(
                  'See all',
                  style: TextStyle(color: Color(0xFF747E78), fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E5E1)),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/profile_1.jpg',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        width: 54,
                        height: 54,
                        color: const Color(0xFFE5EEE8),
                        child: const Icon(Icons.person, color: primaryGreen),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heritage Explorer',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: darkGreen,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'Travel Enthusiast',
                        style: TextStyle(
                          color: Color(0xFF858C87),
                          fontSize: 11,
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        'Community member',
                        style: TextStyle(
                          color: Color(0xFF858C87),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const _FollowButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FOLLOW BUTTON
// ============================================================================

class _FollowButton extends StatefulWidget {
  const _FollowButton();

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          _following = !_following;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: _following ? const Color(0xFF19784E) : const Color(0xFFEAF5EE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFAAD8BD)),
        ),
        child: Text(
          _following ? 'Following' : 'Follow',
          style: TextStyle(
            color: _following ? Colors.white : const Color(0xFF19784E),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

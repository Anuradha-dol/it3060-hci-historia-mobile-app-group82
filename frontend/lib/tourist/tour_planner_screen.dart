import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historical_place_model.dart';
import '../models/tour_model.dart';
import '../booking/guide_directory_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/historical_place_service.dart';
import '../services/tour_service.dart';
import 'historical_place_details_screen.dart';

class TourPlannerScreen extends StatefulWidget {
  final HistoricalPlaceModel? initialPlace;

  const TourPlannerScreen({super.key, this.initialPlace});

  @override
  State<TourPlannerScreen> createState() => _TourPlannerScreenState();
}

class _TourPlannerScreenState extends State<TourPlannerScreen> {
  static const Color primaryGreen = Color(0xFF176B45);

  final _placeService = HistoricalPlaceService();
  final _tourService = TourService();
  final _searchController = TextEditingController();

  List<HistoricalPlaceModel> _places = [];
  final List<HistoricalPlaceModel> _selectedPlaces = [];
  List<TourModel> _myTours = [];

  bool _loading = true;
  bool _creating = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    if (widget.initialPlace != null) {
      _selectedPlaces.add(widget.initialPlace!);
    }

    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = context.read<AuthProvider>().user?.id;
      final places = await _placeService.getAllPlaces();
      final tours = userId == null
          ? <TourModel>[]
          : await _tourService.getUserTours(userId);

      if (!mounted) return;

      setState(() {
        _places = places;
        _myTours = tours;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  Future<void> _search(String value) async {
    final query = value.trim();

    try {
      final places = query.isEmpty
          ? await _placeService.getAllPlaces()
          : await _placeService.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        _places = places;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _error = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(value),
    );
  }

  bool _isSelected(HistoricalPlaceModel place) {
    return _selectedPlaces.any((item) => item.id == place.id);
  }

  void _togglePlace(HistoricalPlaceModel place) {
    setState(() {
      if (_isSelected(place)) {
        _selectedPlaces.removeWhere((item) => item.id == place.id);
      } else {
        _selectedPlaces.add(place);
      }
    });
  }

  void _openPlaceDetails(HistoricalPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoricalPlaceDetailsScreen(place: place),
      ),
    );
  }

  void _openGuidesForHistoricalPlace(HistoricalPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideDirectoryScreen(
          initialArea: _searchAreaForHistoricalPlace(place),
        ),
      ),
    );
  }

  String _searchAreaForHistoricalPlace(HistoricalPlaceModel place) {
    final location = place.location.trim();

    if (location.isNotEmpty) {
      return location;
    }

    return place.name.trim();
  }

  Future<void> _createTour() async {
    if (_selectedPlaces.isEmpty || _creating) {
      _showMessage('Select at least one historical place.', error: true);
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;

    if (userId == null) {
      _showMessage('Please log in before creating a tour.', error: true);
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final tour = await _tourService.createTour(
        userId: userId,
        title: 'Historical Discovery Tour',
        historicalPlaceIds: _selectedPlaces.map((place) => place.id).toList(),
      );

      if (!mounted) return;

      setState(() {
        _creating = false;
      });

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TourProgressScreen(initialTour: tour),
        ),
      );

      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _creating = false;
      });

      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  void _openTour(TourModel tour) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TourProgressScreen(initialTour: tour)),
    ).then((_) => _loadData());
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : primaryGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Create Tour'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF173D2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  children: [
                    _searchField(),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      'Search & Add Places',
                      'Only admin-added historical places are shown here.',
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      _stateBox(_error!, Icons.cloud_off_outlined)
                    else
                      _placesGrid(),
                    const SizedBox(height: 22),
                    _selectedSection(),
                    const SizedBox(height: 24),
                    _startButton(),
                    if (_myTours.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _sectionTitle('My Tours', 'Continue an existing tour.'),
                      const SizedBox(height: 12),
                      ..._myTours.map(_tourTile),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search historical place',
        prefixIcon: const Icon(Icons.search, color: primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFDDE9E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFDDE9E2)),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF173D2E),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF758179), fontSize: 11),
        ),
      ],
    );
  }

  Widget _placesGrid() {
    if (_places.isEmpty) {
      return _stateBox('No historical places found.', Icons.search_off);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _places.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final place = _places[index];
        final selected = _isSelected(place);

        return InkWell(
          onTap: () => _togglePlace(place),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? primaryGreen : const Color(0xFFDDE9E2),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _placeImage(place.mainImageUrl),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _placeViewButton(
                          onTap: () => _openPlaceDetails(place),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF173D2E),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              place.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF79857E),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: selected
                            ? primaryGreen
                            : const Color(0xFFE9F3EE),
                        child: Icon(
                          selected ? Icons.check : Icons.add,
                          color: selected ? Colors.white : primaryGreen,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectedSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Selected Places (${_selectedPlaces.length})',
                  'This order becomes your route list.',
                ),
              ),
              IconButton(
                tooltip: 'Clear selected places',
                onPressed: _selectedPlaces.isEmpty
                    ? null
                    : () {
                        setState(_selectedPlaces.clear);
                      },
                icon: const Icon(Icons.clear_all, color: primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedPlaces.isEmpty)
            const Text(
              'No places selected yet.',
              style: TextStyle(color: Color(0xFF758179), fontSize: 12),
            )
          else ...[
            ...List.generate(_selectedPlaces.length, (index) {
              final place = _selectedPlaces[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _selectedPlaces.length - 1 ? 0 : 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryGreen,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 50,
                      height: 42,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _placeImage(place.mainImageUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173D2E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _placeViewButton(
                      onTap: () => _openPlaceDetails(place),
                      compact: true,
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      onPressed: () => _togglePlace(place),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            _selectedGuideButton(),
          ],
        ],
      ),
    );
  }

  Widget _selectedGuideButton() {
    final place = _selectedPlaces.first;
    final label = _selectedPlaces.length == 1
        ? 'Need a Guide for ${place.name}'
        : 'Need a Guide for this tour';

    return SizedBox(
      height: 46,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _openGuidesForHistoricalPlace(place),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeViewButton({required VoidCallback onTap, bool compact = false}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: compact ? 0 : 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 7 : 8),
          child: Icon(
            Icons.visibility_outlined,
            color: primaryGreen,
            size: compact ? 18 : 19,
          ),
        ),
      ),
    );
  }

  Widget _startButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _creating ? null : _createTour,
        icon: _creating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_forward_rounded),
        label: Text(_creating ? 'Creating Tour...' : 'Next'),
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: const Color(0xFF91B5A1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
    );
  }

  Widget _tourTile(TourModel tour) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openTour(tour),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDDE9E2)),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE9F3EE),
          child: Text(
            '${tour.progressPercentage}%',
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(tour.title),
        subtitle: Text('${tour.places.length} places - ${tour.status}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _stateBox(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF69736E), size: 34),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF69736E)),
          ),
        ],
      ),
    );
  }
}

class TourProgressScreen extends StatefulWidget {
  final TourModel initialTour;

  const TourProgressScreen({super.key, required this.initialTour});

  @override
  State<TourProgressScreen> createState() => _TourProgressScreenState();
}

class _TourProgressScreenState extends State<TourProgressScreen> {
  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF173D2E);
  static const Color pageBackground = Color(0xFFF4F6F3);

  final _tourService = TourService();

  late TourModel _tour = widget.initialTour;
  bool _saving = false;

  int get _completedCount =>
      _tour.places.where((place) => place.completed).length;

  double get _progressValue =>
      _tour.progressPercentage.clamp(0, 100).toDouble() / 100;

  String get _statusText => _formatStatus(_tour.status);

  String? get _tourDateText => _formatStoredDate(_tour.tourDate);

  String? get _coverImageUrl {
    for (final place in _tour.places) {
      final imageUrl = place.mainImageUrl?.trim();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    return null;
  }

  Future<void> _refresh() async {
    final latest = await _tourService.getTourById(_tour.id);

    if (!mounted) return;

    setState(() {
      _tour = latest;
    });
  }

  Future<void> _togglePlace(TourPlaceModel place) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated = await _tourService.updatePlaceStatus(
        tourId: _tour.id,
        historicalPlaceId: place.historicalPlaceId,
        completed: !place.completed,
      );

      if (!mounted) return;

      setState(() {
        _tour = updated;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  Future<void> _completeOrContinue() async {
    if (_tour.progressPercentage < 100) {
      _showMessage('Mark all places as completed first.', error: true);
      return;
    }

    if (_tour.status.toUpperCase() == 'COMPLETED') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourCompletedScreen(tour: _tour)),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final completed = await _tourService.completeTour(_tour.id);

      if (!mounted) return;

      setState(() {
        _tour = completed;
        _saving = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TourCompletedScreen(tour: completed)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  void _openGuidesForPlace(TourPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GuideDirectoryScreen(initialArea: _searchAreaForPlace(place)),
      ),
    );
  }

  Future<void> _openNearbyPlaces(TourPlaceModel place) async {
    final area = _searchAreaForPlace(place);
    final query = 'tourist attractions near $area';
    final mapUri = Uri(
      scheme: 'geo',
      path: '0,0',
      queryParameters: {'q': query},
    );
    final webUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    try {
      final openedMap = await launchUrl(
        mapUri,
        mode: LaunchMode.externalApplication,
      );

      if (openedMap) return;

      final openedWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (!openedWeb && mounted) {
        _showMessage('Unable to open nearby places.', error: true);
      }
    } on MissingPluginException {
      if (mounted) {
        _showMessage(
          'Please fully restart the app once so Nearby Places can open.',
          error: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open nearby places.', error: true);
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : primaryGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _tour.progressPercentage >= 100;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: const Text('Tour Details'),
        backgroundColor: pageBackground,
        foregroundColor: darkGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              _overviewCard(),
              const SizedBox(height: 16),
              _itineraryHeader(),
              const SizedBox(height: 10),
              if (_tour.places.isEmpty)
                _emptyItinerary()
              else
                ...List.generate(_tour.places.length, (index) {
                  return _placeTile(
                    _tour.places[index],
                    index,
                    index == _tour.places.length - 1,
                  );
                }),
              const SizedBox(height: 16),
              _actionButtons(completed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 58,
                  child: _placeImage(_coverImageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tour.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 18,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_completedCount of ${_tour.places.length} places completed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tourInfoChips(),
          const SizedBox(height: 14),
          _progressSection(),
        ],
      ),
    );
  }

  Widget _tourInfoChips() {
    final chips = <Widget>[
      if (_tourDateText != null)
        _infoChip(Icons.calendar_month_outlined, _tourDateText!),
      _infoChip(Icons.location_on_outlined, '${_tour.places.length} places'),
      _infoChip(Icons.timeline_outlined, '${_tour.progressPercentage}%'),
      _infoChip(Icons.flag_outlined, _statusText),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressSection() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Tour Progress',
              style: TextStyle(
                color: darkGreen,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '$_completedCount / ${_tour.places.length} completed',
              style: const TextStyle(
                color: Color(0xFF8A9690),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 9,
            backgroundColor: const Color(0xFFE2E9E5),
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_tour.progressPercentage}%',
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itineraryHeader() {
    return Row(
      children: [
        const Text(
          'Your Itinerary',
          style: TextStyle(
            color: darkGreen,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh tour',
          onPressed: _saving ? null : () => _refresh(),
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.refresh, color: primaryGreen, size: 20),
        ),
      ],
    );
  }

  Widget _emptyItinerary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EEE7)),
      ),
      child: const Text(
        'No places are available for this tour.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF718078), fontSize: 12),
      ),
    );
  }

  Widget _placeTile(TourPlaceModel place, int index, bool isLast) {
    final completed = place.completed;
    final order = place.placeOrder > 0 ? place.placeOrder : index + 1;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: completed ? primaryGreen : const Color(0xFFC9D2CD),
                    shape: BoxShape.circle,
                    boxShadow: completed
                        ? [
                            BoxShadow(
                              color: primaryGreen.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$order',
                    style: TextStyle(
                      color: completed ? Colors.white : const Color(0xFF6C7771),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 122,
                    color: completed
                        ? primaryGreen.withValues(alpha: 0.25)
                        : const Color(0xFFE0E7E2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE4EEE8)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 66,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _placeImage(place.mainImageUrl),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.historicalPlaceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (place.location.trim().isNotEmpty)
                              Text(
                                place.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF758179),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (_formatStoredDate(place.completedAt) !=
                                null) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Visited ${_formatStoredDate(place.completedAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8B9690),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            _statusButton(place),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _placeActionButton(
                          icon: Icons.support_agent_outlined,
                          label: 'Need a Guide',
                          onTap: () => _openGuidesForPlace(place),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _placeActionButton(
                          icon: Icons.travel_explore_outlined,
                          label: 'Nearby Places',
                          onTap: () => _openNearbyPlaces(place),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFEAF5EE),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primaryGreen, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(TourPlaceModel place) {
    final completed = place.completed;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _saving ? null : () => _togglePlace(place),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFFE6F4EB) : const Color(0xFFF0F3F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (completed) ...[
              const Icon(Icons.check_rounded, color: primaryGreen, size: 13),
              const SizedBox(width: 4),
            ],
            Text(
              completed ? 'Completed' : 'Pending',
              style: TextStyle(
                color: completed ? primaryGreen : const Color(0xFF758179),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(bool completed) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => _refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _saving ? null : _completeOrContinue,
              icon: Icon(
                completed ? Icons.emoji_events_outlined : Icons.play_arrow,
                size: 18,
              ),
              label: Text(completed ? 'View Summary' : 'Continue Tour'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: const Color(0xFF91B5A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatStatus(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return 'Status';
    }

    return normalized
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String? _formatStoredDate(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed.split('T').first;
  }

  String _searchAreaForPlace(TourPlaceModel place) {
    final location = place.location.trim();

    if (location.isNotEmpty) {
      return location;
    }

    return place.historicalPlaceName.trim();
  }
}

class TourCompletedScreen extends StatelessWidget {
  final TourModel tour;

  const TourCompletedScreen({super.key, required this.tour});

  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF173D2E);

  int get _completedCount =>
      tour.places.where((place) => place.completed).length;

  String? get _mainImageUrl {
    for (final place in tour.places) {
      final imageUrl = place.mainImageUrl?.trim();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    return null;
  }

  String get _statusText {
    final value = tour.status.trim();

    if (value.isEmpty) {
      return 'Completed';
    }

    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String? get _tourDateText {
    final value = tour.tourDate?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value.split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('View Summary'),
        backgroundColor: const Color(0xFFF8FAF7),
        foregroundColor: darkGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDDE9E2)),
              ),
              child: Column(
                children: [
                  _summaryHero(),
                  const SizedBox(height: 42),
                  const Text(
                    'Tour Completed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'You completed $_completedCount of ${tour.places.length} historical places.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _statsRow(),
                  if (_tourDateText != null) ...[
                    const SizedBox(height: 10),
                    _tourDateCard(),
                  ],
                  const SizedBox(height: 22),
                  _journeySection(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryHero() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 185,
          width: double.infinity,
          child: _placeImage(_mainImageUrl),
        ),
        Positioned(
          bottom: -34,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              Icons.location_on_outlined,
              '$_completedCount',
              'Places Visited',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              Icons.check_circle_outline,
              '${tour.progressPercentage}%',
              'Tour Progress',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCard(
              Icons.flag_outlined,
              _statusText,
              'Status',
              compactValue: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tourDateCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2EEE7)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: primaryGreen, size: 20),
            const SizedBox(width: 10),
            const Text(
              'Tour Date',
              style: TextStyle(
                color: Color(0xFF718078),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              _tourDateText!,
              style: const TextStyle(
                color: darkGreen,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _journeySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Journey',
            style: TextStyle(
              color: darkGreen,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (tour.places.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2EEE7)),
              ),
              child: const Text(
                'No historical places were added to this tour.',
                style: TextStyle(color: Color(0xFF718078), fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tour.places.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final place = tour.places[index];

                  return _journeyPlaceCard(place, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _journeyPlaceCard(TourPlaceModel place, int index) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _placeImage(place.mainImageUrl),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            place.historicalPlaceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                place.completed
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: place.completed ? primaryGreen : const Color(0xFF9BA8A0),
                size: 13,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  place.completed ? 'Completed' : 'Not completed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718078),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    IconData icon,
    String value,
    String label, {
    bool compactValue = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1EEE5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryGreen, size: 21),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: compactValue ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w900,
              fontSize: compactValue ? 12 : 17,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF718078),
              fontSize: 9,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _placeImage(String? imageUrl) {
  final value = imageUrl?.trim() ?? '';

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagePlaceholder(),
    );
  }

  if (value.startsWith('assets/')) {
    return Image.asset(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagePlaceholder(),
    );
  }

  return _imagePlaceholder();
}

Widget _imagePlaceholder() {
  return Container(
    color: const Color(0xFFE6EEE9),
    alignment: Alignment.center,
    child: const Icon(
      Icons.account_balance_outlined,
      color: Color(0xFF176B45),
      size: 30,
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/historical_place_model.dart';
import '../models/tour_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/historical_place_service.dart';
import '../services/tour_service.dart';

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
                Expanded(child: _placeImage(place.mainImageUrl)),
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
          else
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
                    IconButton(
                      onPressed: () => _togglePlace(place),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              );
            }),
        ],
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

  final _tourService = TourService();

  late TourModel _tour = widget.initialTour;
  bool _saving = false;

  int get _completedCount =>
      _tour.places.where((place) => place.completed).length;

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
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Tour Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF173D2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _progressCard(),
              const SizedBox(height: 18),
              const Text(
                'Your Itinerary',
                style: TextStyle(
                  color: Color(0xFF173D2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ..._tour.places.map(_placeTile),
              const SizedBox(height: 18),
              _guideButton(),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _completeOrContinue,
                  icon: Icon(
                    completed
                        ? Icons.emoji_events_outlined
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(completed ? 'View Summary' : 'Continue Tour'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: const Color(0xFF91B5A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tour.title,
            style: const TextStyle(
              color: Color(0xFF173D2E),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_tour.places.length} places - $_completedCount completed',
            style: const TextStyle(color: Color(0xFF718078), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _tour.progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E9E5),
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_tour.progressPercentage}%',
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeTile(TourPlaceModel place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: place.completed
                ? primaryGreen
                : const Color(0xFFDDE6E1),
            child: Text(
              '${place.placeOrder}',
              style: TextStyle(
                color: place.completed ? Colors.white : const Color(0xFF708078),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
                    color: Color(0xFF173D2E),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  place.location.isEmpty
                      ? 'Location not added'
                      : place.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF758179),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _saving ? null : () => _togglePlace(place),
            style: TextButton.styleFrom(
              foregroundColor: place.completed ? primaryGreen : Colors.orange,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(place.completed ? 'Completed' : 'Pending'),
          ),
        ],
      ),
    );
  }

  Widget _guideButton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE4F2EA),
            child: Icon(Icons.support_agent, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a Tour Guide?',
                  style: TextStyle(
                    color: Color(0xFF173D2E),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Guide booking can be connected from here.',
                  style: TextStyle(color: Color(0xFF758179), fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              _showMessage('Guide booking button is ready.');
            },
            child: const Text('Book Guide'),
          ),
        ],
      ),
    );
  }
}

class TourCompletedScreen extends StatelessWidget {
  final TourModel tour;

  const TourCompletedScreen({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF176B45);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Tour Completed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF173D2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: primaryGreen,
              child: Icon(Icons.emoji_events, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tour Completed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF173D2E),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You explored ${tour.places.length} historical places.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718078)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    Icons.location_on_outlined,
                    '${tour.places.length}',
                    'Places Visited',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    Icons.check_circle_outline,
                    '${tour.progressPercentage}%',
                    'Progress',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Journey',
              style: TextStyle(
                color: Color(0xFF173D2E),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tour.places.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      child: _placeImage(tour.places[index].mainImageUrl),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF176B45)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF173D2E),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF718078), fontSize: 11),
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/historical_place_model.dart';
import '../services/api_service.dart';
import '../services/historical_place_service.dart';

class AdminPlaceManagerScreen extends StatefulWidget {
  const AdminPlaceManagerScreen({super.key});

  @override
  State<AdminPlaceManagerScreen> createState() =>
      _AdminPlaceManagerScreenState();
}

class _AdminPlaceManagerScreenState extends State<AdminPlaceManagerScreen> {
  static const Color primaryGreen = Color(0xFF176B45);

  final _service = HistoricalPlaceService();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _location = TextEditingController();
  final _story = TextEditingController();
  final _fee = TextEditingController();
  final _hours = TextEditingController();

  List<HistoricalPlaceModel> _places = [];
  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _subtitle,
      _location,
      _story,
      _fee,
      _hours,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _service.getAllPlaces();

      if (!mounted) return;

      setState(() {
        _places = places;
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

  Future<void> _pickImages() async {
    final remaining = 3 - _images.length;

    if (remaining <= 0) {
      _showMessage('Only 3 images are needed.', error: true);
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );

      if (picked.isEmpty) return;

      final selected = picked.take(remaining).toList();
      final bytes = <Uint8List>[];

      for (final image in selected) {
        bytes.add(await image.readAsBytes());
      }

      if (!mounted) return;

      setState(() {
        _images.addAll(selected);
        _imageBytes.addAll(bytes);
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to select images.', error: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  Future<void> _createPlace() async {
    if (_saving) return;

    if (_name.text.trim().isEmpty ||
        _location.text.trim().isEmpty ||
        _story.text.trim().isEmpty) {
      _showMessage('Name, location, and story are required.', error: true);
      return;
    }

    if (_imageBytes.length != 3) {
      _showMessage('Please add exactly 3 images.', error: true);
      return;
    }

    final entranceFee = double.tryParse(_fee.text.trim()) ?? 0;

    setState(() {
      _saving = true;
    });

    try {
      final imageUrls = <String>[];

      for (int i = 0; i < _imageBytes.length; i++) {
        final url = await _service.uploadPlaceImage(
          imageBytes: _imageBytes[i],
          fileName: _images[i].name,
        );

        imageUrls.add(url);
      }

      await _service.createPlace(
        name: _name.text,
        subtitle: _subtitle.text,
        location: _location.text,
        description: _story.text,
        entranceFee: entranceFee,
        openingHours: _hours.text,
        imageUrls: imageUrls,
      );

      _clearForm();

      await _loadPlaces();

      if (!mounted) return;

      _showMessage('Historical place added.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _clearForm() {
    _name.clear();
    _subtitle.clear();
    _location.clear();
    _story.clear();
    _fee.clear();
    _hours.clear();
    _images.clear();
    _imageBytes.clear();
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
        title: const Text('Historical Places'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF173D2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _loadPlaces,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              _formCard(),
              const SizedBox(height: 24),
              const Text(
                'Added Places',
                style: TextStyle(
                  color: Color(0xFF173D2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                )
              else if (_error != null)
                _stateBox(_error!)
              else if (_places.isEmpty)
                _stateBox('No historical places added yet.')
              else
                ..._places.map(_placeCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
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
          const Text(
            'Add Historical Place',
            style: TextStyle(
              color: Color(0xFF173D2E),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add the story, visitor price, and 3 images.',
            style: TextStyle(color: Color(0xFF718078), fontSize: 11),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Place name', Icons.account_balance_outlined),
          const SizedBox(height: 12),
          _field(_subtitle, 'Short subtitle', Icons.short_text),
          const SizedBox(height: 12),
          _field(_location, 'Location', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _field(
            _fee,
            'Tourist entrance price',
            Icons.confirmation_number_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _field(_hours, 'Opening hours', Icons.schedule_outlined),
          const SizedBox(height: 12),
          _field(
            _story,
            'Story about this historical place',
            Icons.notes_outlined,
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          _imagePicker(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving ? null : _createPlace,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Saving...' : 'Add Place'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: const Color(0xFF91B5A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: const Color(0xFFF8FAF7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE9E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE9E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int i = 0; i < _imageBytes.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes[i],
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _removeImage(i),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        if (_images.length < 3)
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFD8C9)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: primaryGreen),
                  SizedBox(height: 5),
                  Text(
                    'Add Image',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeCard(HistoricalPlaceModel place) {
    final images = place.galleryImages.isNotEmpty
        ? place.galleryImages
        : [
            if ((place.mainImageUrl ?? '').trim().isNotEmpty)
              place.mainImageUrl!,
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.name,
            style: const TextStyle(
              color: Color(0xFF173D2E),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            place.location,
            style: const TextStyle(color: Color(0xFF718078), fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 90,
                    child: _networkImage(images[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkImage(String value) {
    final imageUrl = ApiConfig.resolveImageUrl(value);

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE6EEE9),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: primaryGreen),
    );
  }

  Widget _stateBox(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF69736E)),
      ),
    );
  }
}

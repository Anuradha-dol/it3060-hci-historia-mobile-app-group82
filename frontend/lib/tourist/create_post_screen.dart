import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/historical_place_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/historical_place_service.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  final HistoricalPlaceModel? initialPlace;

  const CreatePostScreen({super.key, this.initialPlace});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const Color primaryGreen = Color(0xFF176B45);
  static const int maxImages = 5;

  final _placeService = HistoricalPlaceService();
  final _postService = PostService();
  final _imagePicker = ImagePicker();
  final _captionController = TextEditingController();
  final _customPlaceController = TextEditingController();

  List<HistoricalPlaceModel> _places = [];
  HistoricalPlaceModel? _selectedPlace;
  final List<XFile> _images = [];
  final List<Uint8List> _imageBytes = [];

  bool _loadingPlaces = true;
  bool _publishing = false;
  String? _placeError;

  @override
  void initState() {
    super.initState();
    _selectedPlace = widget.initialPlace;
    _loadPlaces();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _customPlaceController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _placeService.getAllPlaces();

      if (!mounted) return;

      setState(() {
        _places = places;
        _selectedPlace = _findInitialPlace(places);
        _loadingPlaces = false;
        _placeError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPlaces = false;
        _placeError = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  HistoricalPlaceModel? _findInitialPlace(List<HistoricalPlaceModel> places) {
    final initial = _selectedPlace;

    if (initial == null) {
      return null;
    }

    for (final place in places) {
      if (place.id == initial.id) {
        return place;
      }
    }

    return initial;
  }

  Future<void> _pickImages() async {
    final remaining = maxImages - _images.length;

    if (remaining <= 0) {
      _showMessage('You can add up to $maxImages photos.', isError: true);
      return;
    }

    try {
      final picked = await _imagePicker.pickMultiImage(
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
      _showMessage('Unable to select photos.', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageBytes.removeAt(index);
    });
  }

  Future<void> _publishPost() async {
    if (_publishing) return;

    final userId = context.read<AuthProvider>().user?.id;

    if (userId == null) {
      _showMessage('Please log in before creating a post.', isError: true);
      return;
    }

    final typedPlace = _customPlaceController.text.trim();

    if (_selectedPlace == null && typedPlace.isEmpty) {
      _showMessage('Select or type a historical place.', isError: true);
      return;
    }

    if (_imageBytes.isEmpty) {
      _showMessage('Please add at least one photo.', isError: true);
      return;
    }

    final caption = _captionController.text.trim();

    if (caption.isEmpty) {
      _showMessage('Please enter a caption.', isError: true);
      return;
    }

    setState(() {
      _publishing = true;
    });

    try {
      final imageUrls = <String>[];

      for (int i = 0; i < _imageBytes.length; i++) {
        final url = await _postService.uploadPostImage(
          imageBytes: _imageBytes[i],
          fileName: _images[i].name,
        );

        imageUrls.add(url);
      }

      await _postService.createPost(
        userId: userId,
        historicalPlaceId: _selectedPlace?.id,
        customPlaceName: _selectedPlace == null ? typedPlace : null,
        caption: caption,
        imageUrls: imageUrls,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(ApiService.instance.getErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _publishing = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : primaryGreen,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF183D2E),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('1. Select Historical Place'),
              const SizedBox(height: 10),
              _buildPlaceSelector(),
              const SizedBox(height: 18),
              _buildTypedPlaceField(),
              const SizedBox(height: 26),
              _sectionTitle('2. Add Photos'),
              const SizedBox(height: 4),
              const Text(
                'You can add up to 5 photos.',
                style: TextStyle(color: Color(0xFF728079), fontSize: 11),
              ),
              const SizedBox(height: 12),
              _buildImageGrid(),
              const SizedBox(height: 26),
              _sectionTitle('3. Add a Caption'),
              const SizedBox(height: 10),
              _buildCaptionField(),
              const SizedBox(height: 26),
              _buildPostButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF183D2E),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildPlaceSelector() {
    if (_loadingPlaces) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_placeError != null) {
      return _messageBox(
        _placeError!,
        actionText: 'Try Again',
        onAction: _loadPlaces,
      );
    }

    if (_places.isEmpty) {
      return _messageBox('No admin-added historical places found.');
    }

    return DropdownButtonFormField<HistoricalPlaceModel>(
      initialValue: _selectedPlace,
      isExpanded: true,
      hint: const Text('Select a historical place'),
      decoration: _fieldDecoration(Icons.location_on_outlined),
      items: _places.map((place) {
        return DropdownMenuItem(
          value: place,
          child: Text(place.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (place) {
        setState(() {
          _selectedPlace = place;

          if (place != null) {
            _customPlaceController.clear();
          }
        });
      },
    );
  }

  Widget _buildTypedPlaceField() {
    return TextField(
      controller: _customPlaceController,
      enabled: _selectedPlace == null,
      onChanged: (value) {
        if (value.trim().isNotEmpty && _selectedPlace != null) {
          setState(() {
            _selectedPlace = null;
          });
        }
      },
      decoration: _fieldDecoration(Icons.edit_location_alt_outlined).copyWith(
        labelText: 'Or type place name',
        hintText: 'Example: Sigiriya',
      ),
    );
  }

  Widget _buildImageGrid() {
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
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (_images.length < maxImages)
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
                    'Add Photos',
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

  Widget _buildCaptionField() {
    return TextField(
      controller: _captionController,
      maxLines: 5,
      maxLength: 500,
      decoration: _fieldDecoration(Icons.notes_outlined).copyWith(
        hintText: 'Share your experience...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildPostButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _publishing ? null : _publishPost,
        icon: _publishing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(_publishing ? 'Posting...' : 'Post'),
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: const Color(0xFF91B5A1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: primaryGreen),
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
    );
  }

  Widget _messageBox(
    String message, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Color(0xFF69736E))),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }
}

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
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final HistoricalPlaceService _historicalPlaceService =
      HistoricalPlaceService();

  final PostService _postService = PostService();

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _captionController = TextEditingController();

  List<HistoricalPlaceModel> _places = [];

  HistoricalPlaceModel? _selectedPlace;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _loadingPlaces = true;
  bool _publishing = false;

  String? _placeError;

  @override
  void initState() {
    super.initState();
    _loadHistoricalPlaces();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOAD HISTORICAL PLACES
  // ------------------------------------------------------------

  Future<void> _loadHistoricalPlaces() async {
    try {
      final places = await _historicalPlaceService.getAllPlaces();

      if (!mounted) return;

      setState(() {
        _places = places;
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

  // ------------------------------------------------------------
  // PICK IMAGE
  // ------------------------------------------------------------

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to select image.', isError: true);
    }
  }

  // ------------------------------------------------------------
  // REMOVE IMAGE
  // ------------------------------------------------------------

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  // ------------------------------------------------------------
  // PUBLISH POST
  // ------------------------------------------------------------

  Future<void> _publishPost() async {
    if (_publishing) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final userId = authProvider.user?.id;

    // Validate logged-in user
    if (userId == null) {
      _showMessage('Please log in before creating a post.', isError: true);
      return;
    }

    // Validate historical place
    if (_selectedPlace == null) {
      _showMessage('Please select a historical place.', isError: true);
      return;
    }

    // Validate image
    if (_selectedImage == null || _selectedImageBytes == null) {
      _showMessage('Please select an image.', isError: true);
      return;
    }

    // Validate caption
    final caption = _captionController.text.trim();

    if (caption.isEmpty) {
      _showMessage('Please enter a caption.', isError: true);
      return;
    }

    setState(() {
      _publishing = true;
    });

    try {
      // STEP 1:
      // Upload selected image to backend.
      final imageUrl = await _postService.uploadPostImage(
        imageBytes: _selectedImageBytes!,
        fileName: _selectedImage!.name,
      );

      // STEP 2:
      // Create post using returned image URL.
      await _postService.createPost(
        userId: userId,
        historicalPlaceId: _selectedPlace!.id,
        caption: caption,
        imageUrls: [imageUrl],
      );

      if (!mounted) return;

      // Return to Home and tell it that a new post was created.
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

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF2F6B4F),
        ),
      );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3ED),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF3A241B),

        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              const Text(
                'Share Your Experience',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A241B),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Share your visit to a historical place with the community.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F6A66),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // HISTORICAL PLACE
              // ------------------------------------------------
              const Text(
                'Historical Place',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A241B),
                ),
              ),

              const SizedBox(height: 10),

              _buildPlaceSelector(),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // PHOTO
              // ------------------------------------------------
              const Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A241B),
                ),
              ),

              const SizedBox(height: 10),

              _buildImagePicker(),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // CAPTION
              // ------------------------------------------------
              const Text(
                'Caption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A241B),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _captionController,
                maxLines: 5,
                maxLength: 500,

                decoration: InputDecoration(
                  hintText: 'Write something about your experience...',

                  hintStyle: const TextStyle(color: Color(0xFF9A9692)),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.all(16),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4D9CF)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF9A4F2D),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // PUBLISH BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: _publishing ? null : _publishPost,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A4F2D),

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: const Color(0xFFC8AAA0),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    elevation: 0,
                  ),

                  child: _publishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Publish Post',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PLACE SELECTOR
  // ------------------------------------------------------------

  Widget _buildPlaceSelector() {
    if (_loadingPlaces) {
      return Container(
        height: 58,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: Color(0xFF9A4F2D)),
      );
    }

    if (_placeError != null) {
      return Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4D9CF)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_placeError!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: _loadHistoricalPlaces,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return const Text('No historical places available.');
    }

    return DropdownButtonFormField<HistoricalPlaceModel>(
      initialValue: _selectedPlace,

      isExpanded: true,

      hint: const Text('Select historical place'),

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF9A4F2D),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4D9CF)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9A4F2D), width: 1.5),
        ),
      ),

      items: _places.map((place) {
        return DropdownMenuItem<HistoricalPlaceModel>(
          value: place,
          child: Text(place.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: (place) {
        setState(() {
          _selectedPlace = place;
        });
      },
    );
  }

  // ------------------------------------------------------------
  // IMAGE PICKER
  // ------------------------------------------------------------

  Widget _buildImagePicker() {
    if (_selectedImageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),

            child: Image.memory(
              _selectedImageBytes!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            top: 10,
            right: 10,

            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),

              child: IconButton(
                onPressed: _removeImage,

                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickImage,

      borderRadius: BorderRadius.circular(16),

      child: Container(
        width: double.infinity,
        height: 180,

        decoration: BoxDecoration(
          color: const Color(0xFFF1E7DC),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xFFD8C5B7)),
        ),

        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 44,
              color: Color(0xFF9A4F2D),
            ),

            SizedBox(height: 12),

            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3A241B),
              ),
            ),

            SizedBox(height: 5),

            Text(
              'Tap to select an image',
              style: TextStyle(color: Color(0xFF6F6A66)),
            ),
          ],
        ),
      ),
    );
  }
}

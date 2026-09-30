import 'package:flutter/material.dart';

import '../models/guide_model.dart';
import '../services/api_service.dart';
import '../services/guide_service.dart';
import '../widgets/form_helpers.dart';

// =====================================================================
// APPROVED GUIDES SCREEN
// =====================================================================

class ApprovedGuidesScreen extends StatelessWidget {
  const ApprovedGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F9F6),
      body: SafeArea(
        child: ApprovedGuidesContent(
          standalone: true,
        ),
      ),
    );
  }
}

// =====================================================================
// APPROVED GUIDES CONTENT
// =====================================================================

class ApprovedGuidesContent extends StatefulWidget {
  final bool standalone;

  const ApprovedGuidesContent({
    super.key,
    this.standalone = false,
  });

  @override
  State<ApprovedGuidesContent> createState() =>
      _ApprovedGuidesContentState();
}

class _ApprovedGuidesContentState
    extends State<ApprovedGuidesContent> {
  final _area = TextEditingController();

  List<GuideModel> _guides = [];

  bool _loading = false;
  bool _searched = false;

  // ===================================================================
  // DISPOSE
  // ===================================================================

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  // ===================================================================
  // SEARCH
  // ===================================================================

  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    final area = _area.text.trim();

    if (area.isEmpty) {
      showAppMessage(
        context,
        'Area is required.',
        error: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final guides =
      await GuideService().getApprovedGuides(
        area: area,
      );

      if (!mounted) return;

      setState(() {
        _guides = guides;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;

      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ===================================================================
  // CLEAR SEARCH
  // ===================================================================

  void _clearSearch() {
    _area.clear();

    setState(() {
      _guides = [];
      _searched = false;
    });
  }

  // ===================================================================
  // BUILD
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =============================================================
        // HEADER
        // =============================================================

        _GuideSearchHeader(
          standalone: widget.standalone,
        ),

        // =============================================================
        // BODY
        // =============================================================

        Expanded(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              28,
            ),
            children: [
              // =======================================================
              // INTRO
              // =======================================================

              const _SectionHeading(
                eyebrow: 'LOCAL GUIDE SEARCH',
                title: 'Where are you exploring?',
                subtitle:
                'Enter a city or heritage area to find approved HISTORIA guides.',
              ),

              const SizedBox(height: 13),

              // =======================================================
              // SEARCH CARD
              // =======================================================

              _SearchCard(
                controller: _area,
                loading: _loading,
                searched: _searched,
                onSearch: _search,
                onClear: _clearSearch,
              ),

              const SizedBox(height: 22),

              // =======================================================
              // RESULTS TITLE
              // =======================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GUIDES',
                          style: TextStyle(
                            color: Color(0xFF4D836B),
                            fontSize: 7.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Search results',
                          style: TextStyle(
                            color: Color(0xFF153D30),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          !_searched
                              ? 'Search by service area.'
                              : _guides.isEmpty
                              ? 'No approved guides found.'
                              : '${_guides.length} approved guide${_guides.length == 1 ? '' : 's'} found.',
                          style: const TextStyle(
                            color: Color(0xFF78887F),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_searched)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F2E9),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_guides.length}',
                        style: const TextStyle(
                          color: Color(0xFF176D4E),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // =======================================================
              // INITIAL STATE
              // =======================================================

              if (!_searched)
                const _InitialSearchState()

              // =======================================================
              // EMPTY RESULT
              // =======================================================

              else if (_guides.isEmpty)
                _NoGuideState(
                  searchedArea: _area.text.trim(),
                )

              // =======================================================
              // GUIDE RESULTS
              // =======================================================

              else
                ..._guides.map(
                      (guide) => _GuideResultCard(
                    guide: guide,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// HEADER
// =====================================================================

class _GuideSearchHeader extends StatelessWidget {
  final bool standalone;

  const _GuideSearchHeader({
    required this.standalone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        11,
        12,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9FCFA),
            Color(0xFFE9F5ED),
            Color(0xFFD9ECDF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            bottom: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF176D4E)
                    .withValues(
                  alpha: 0.055,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 12,
            bottom: -8,
            child: Icon(
              Icons.travel_explore_rounded,
              size: 90,
              color: const Color(0xFF176D4E)
                  .withValues(
                alpha: 0.07,
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =======================================================
              // BRAND
              // =======================================================

              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F1E7),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      size: 20,
                      color: Color(0xFF176D4E),
                    ),
                  ),

                  const SizedBox(width: 9),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HISTORIA',
                          style: TextStyle(
                            color: Color(0xFF153D30),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),

                        SizedBox(height: 1),

                        Text(
                          'EXPLORE HISTORY · FIND YOUR GUIDE',
                          style: TextStyle(
                            color: Color(0xFF75877E),
                            fontSize: 6.1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (standalone)
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF176D4E),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // =======================================================
              // PAGE INFO
              // =======================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.70,
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD0E5D8),
                  ),
                ),
                child: const Text(
                  'TOURIST / GUIDE DISCOVERY',
                  style: TextStyle(
                    color: Color(0xFF39765D),
                    fontSize: 7.2,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Find a local guide.',
                style: TextStyle(
                  color: Color(0xFF143C2F),
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Search approved guides by the places they serve.',
                style: TextStyle(
                  color: Color(0xFF697E73),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SECTION HEADING
// =====================================================================

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: Color(0xFF4E846C),
            fontSize: 7.4,
            letterSpacing: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF153D30),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF798980),
            fontSize: 9,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// SEARCH CARD
// =====================================================================

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;

  final bool loading;
  final bool searched;

  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchCard({
    required this.controller,
    required this.loading,
    required this.searched,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDCE8E1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0A3A2B),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: Color(0xFF176D4E),
                size: 18,
              ),

              SizedBox(width: 7),

              Expanded(
                child: Text(
                  'Approved guides only',
                  style: TextStyle(
                    color: Color(0xFF214D3D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Search results are returned from approved guide records.',
            style: TextStyle(
              color: Color(0xFF7A8981),
              fontSize: 8,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              onSearch();
            },
            decoration: InputDecoration(
              hintText: 'Enter service area',
              hintStyle: const TextStyle(
                color: Color(0xFF9AA59F),
                fontSize: 11,
              ),

              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF4E7A65),
                size: 20,
              ),

              suffixIcon: controller.text.isNotEmpty ||
                  searched
                  ? IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF72837A),
                ),
              )
                  : null,

              filled: true,
              fillColor: const Color(0xFFF7FAF8),

              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 14,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFFD5E5DB),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF3A8667),
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 11),

          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed:
              loading ? null : onSearch,
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFF176D4E),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(13),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.search_rounded,
                size: 19,
              ),
              label: Text(
                loading
                    ? 'Searching...'
                    : 'Search guides',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// INITIAL STATE
// =====================================================================

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        27,
        22,
        25,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF1F7F3),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDDE8E1),
        ),
      ),
      child: const Column(
        children: [
          _SearchIllustration(
            icon: Icons.travel_explore_rounded,
          ),

          SizedBox(height: 16),

          Text(
            'Search for a local guide',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF153D30),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Enter the service area where you want to find an approved HISTORIA guide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF75867D),
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// NO GUIDE STATE
// =====================================================================

class _NoGuideState extends StatelessWidget {
  final String searchedArea;

  const _NoGuideState({
    required this.searchedArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        27,
        22,
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDDE8E1),
        ),
      ),
      child: Column(
        children: [
          const _SearchIllustration(
            icon: Icons.person_search_outlined,
          ),

          const SizedBox(height: 16),

          const Text(
            'No approved guides found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF153D30),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            searchedArea.isEmpty
                ? 'Try another service area.'
                : 'No approved guide was returned for "$searchedArea". Try another service area.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF75867D),
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SEARCH ILLUSTRATION
// =====================================================================

class _SearchIllustration extends StatelessWidget {
  final IconData icon;

  const _SearchIllustration({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F2EA),
            shape: BoxShape.circle,
          ),
        ),

        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD2E5D8),
            ),
          ),
          child: Icon(
            icon,
            size: 29,
            color: const Color(0xFF176D4E),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// GUIDE RESULT CARD
// =====================================================================

class _GuideResultCard extends StatelessWidget {
  final GuideModel guide;

  const _GuideResultCard({
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final languages = guide.languages.isEmpty
        ? 'Not provided'
        : guide.languages.join(', ');

    final initials =
    _getInitials(guide.title);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFDCE8E1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A093B2B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ===========================================================
          // GUIDE IDENTITY
          // ===========================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDEFE4),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF176B4C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        color: Color(0xFF153D30),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      guide.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF77877F),
                        fontSize: 8.5,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFF176E4D),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ APPROVED GUIDE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.7,
                          letterSpacing: 0.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ===========================================================
          // AREA
          // ===========================================================

          _GuideInfoLine(
            icon: Icons.location_on_outlined,
            label: 'Primary service area',
            value: guide.primaryServiceArea,
          ),

          const _GuideDivider(),

          // ===========================================================
          // LANGUAGES
          // ===========================================================

          _GuideInfoLine(
            icon: Icons.translate_outlined,
            label: 'Languages',
            value: languages,
          ),

          // ===========================================================
          // SPECIALTIES
          // ===========================================================

          if (guide.specialties.isNotEmpty) ...[
            const _GuideDivider(),

            const SizedBox(height: 10),

            const Text(
              'SPECIALTIES',
              style: TextStyle(
                color: Color(0xFF74857C),
                fontSize: 7,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: guide.specialties
                  .map(
                    (specialty) => Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFE8F3EB),
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color:
                      const Color(0xFFD0E4D7),
                    ),
                  ),
                  child: Text(
                    specialty,
                    style: const TextStyle(
                      color:
                      Color(0xFF2B6A51),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ],

          // ===========================================================
          // BIO
          // ===========================================================

          if (guide.bio != null &&
              guide.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F6),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Text(
                guide.bio!,
                style: const TextStyle(
                  color: Color(0xFF65786E),
                  fontSize: 9,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _getInitials(
      String value,
      ) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return 'G';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

// =====================================================================
// GUIDE INFO
// =====================================================================

class _GuideInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GuideInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F3EA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF267154),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B8982),
                    fontSize: 7.8,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value.trim().isEmpty
                      ? 'Not provided'
                      : value,
                  style: const TextStyle(
                    color: Color(0xFF223F34),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideDivider extends StatelessWidget {
  const _GuideDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xFFE7EEE9),
    );
  }
}
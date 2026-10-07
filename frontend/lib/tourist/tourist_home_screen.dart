import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/historical_place_model.dart';
import '../profile/profile_screen.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/historical_place_service.dart';
import '../services/post_service.dart';
import '../widgets/community_feed.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'checkout_screen.dart';
import 'create_post_screen.dart';
import 'historical_search_screen.dart';
import 'notifications_screen.dart';
import 'review_screen.dart';
import 'tour_planner_screen.dart';

// ============================================================================
// TOURIST HOME SCREEN
// ============================================================================

class TouristHomeScreen extends StatefulWidget {
  const TouristHomeScreen({super.key});

  @override
  State<TouristHomeScreen> createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  static const Color background = Color(0xFFF8FAF7);

  int _index = 0;
  int _postRefreshKey = 0;
  final _bookingService = BookingService();
  bool _creatingBooking = false;

  // --------------------------------------------------------------------------
  // OPEN HOME
  // --------------------------------------------------------------------------

  void _openHome() {
    if (_index == 0) {
      return;
    }

    setState(() {
      _index = 0;
    });
  }

  // --------------------------------------------------------------------------
  // OPEN PROFILE
  // --------------------------------------------------------------------------

  void _openProfile() {
    if (_index == 4) {
      return;
    }

    setState(() {
      _index = 4;
    });
  }

  // --------------------------------------------------------------------------
  // OPEN NOTIFICATIONS
  // --------------------------------------------------------------------------

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN SEARCH
  // --------------------------------------------------------------------------

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoricalSearchScreen()),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN CREATE POST
  // --------------------------------------------------------------------------

  Future<void> _openCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (!mounted) {
      return;
    }

    // CreatePostScreen returns true after a successful post.
    if (created == true) {
      setState(() {
        _index = 0;

        // Recreates the dashboard and loads the newest posts.
        _postRefreshKey++;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Post published successfully!'),
            backgroundColor: Color(0xFF176B45),
          ),
        );
    }
  }

  void _openTourPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TourPlannerScreen()),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN CHECKOUT
  // --------------------------------------------------------------------------

  Future<void> _openCheckout() async {
    if (_creatingBooking) return;

    setState(() => _creatingBooking = true);

    try {
      final booking = await _bookingService.createDemoBooking();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(booking: booking),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;

      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(error),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _creatingBooking = false);
    }
  }

  // --------------------------------------------------------------------------
  // OPEN REVIEW
  // --------------------------------------------------------------------------

  Future<void> _openReview() async {
    try {
      final bookings = await _bookingService.getMyBookings();

      final reviewable = bookings
          .where((booking) => booking.isPaid && !booking.reviewed)
          .toList();

      if (!mounted) return;

      if (reviewable.isEmpty) {
        showAppMessage(
          context,
          'Complete a booking payment before leaving a review.',
        );
        return;
      }

      final booking = reviewable.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            bookingId: booking.id!,
            tourTitle: booking.guideName,
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;

      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(error),
        error: true,
      );
    }
  }

  // --------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------------------------------

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _openHome();
        break;

      case 1:
        _openTourPlanner();
        break;

      case 2:
        _openCreatePost();
        break;

      case 3:
        _openSearch();
        break;

      case 4:
        _openProfile();
        break;
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: IndexedStack(
          index: _index == 4 ? 1 : 0,
          children: [
            _TouristDashboard(
              key: ValueKey(_postRefreshKey),
              onNotifications: _openNotifications,
              onProfile: _openProfile,
              onSearch: _openSearch,
              onCheckout: _openCheckout,
              onReview: _openReview,
            ),

            RoleProfileContent(
              onTouristGuides: () {},
              onNotifications: _openNotifications,
            ),
          ],
        ),
      ),

      bottomNavigationBar: HistoriaBottomNavigation(
        currentIndex: _index,
        onTap: _onBottomNavTap,
        items: const [
          HistoriaNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          HistoriaNavItem(
            icon: Icons.map_outlined,
            activeIcon: Icons.map,
            label: 'Tour',
          ),
          HistoriaNavItem(
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle,
            label: 'Create Post',
          ),
          HistoriaNavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Explore',
          ),
          HistoriaNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOME DASHBOARD
// ============================================================================

class _TouristDashboard extends StatefulWidget {
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onCheckout;
  final VoidCallback onReview;

  const _TouristDashboard({
    super.key,
    required this.onNotifications,
    required this.onProfile,
    required this.onSearch,
    required this.onCheckout,
    required this.onReview,
  });

  @override
  State<_TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<_TouristDashboard> {
  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF123D2D);

  final HistoricalPlaceService _placeService = HistoricalPlaceService();

  List<HistoricalPlaceModel> _topTourPlaces = [];

  int _feedKey = 0;
  bool _loadingTopPlaces = true;
  String? _topPlacesError;

  @override
  void initState() {
    super.initState();
    _loadTopTourPlaces();
  }

  Future<void> _loadTopTourPlaces() async {
    if (mounted) {
      setState(() {
        _loadingTopPlaces = true;
        _topPlacesError = null;
      });
    }

    try {
      final places = await _placeService.getTopTourPlaces(limit: 5);

      if (!mounted) return;

      setState(() {
        _topTourPlaces = places.take(5).toList();
        _loadingTopPlaces = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _topTourPlaces = [];
        _loadingTopPlaces = false;
        _topPlacesError = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _feedKey++;
    });

    await _loadTopTourPlaces();
  }

  void _openTourWithPlace(HistoricalPlaceModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TourPlannerScreen(initialPlace: place)),
    );
  }

  Widget _buildTopTourPlaces() {
    if (_loadingTopPlaces) {
      return const SizedBox(
        height: 145,
        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_topPlacesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _TopPlacesMessage(
          icon: Icons.cloud_off_outlined,
          message: _topPlacesError!,
          onRetry: _loadTopTourPlaces,
        ),
      );
    }

    if (_topTourPlaces.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: _TopPlacesMessage(
          icon: Icons.route_outlined,
          message: 'No trending places yet.',
        ),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _topTourPlaces.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final place = _topTourPlaces[index];

          return _TrendingPlaceCard(
            image: place.mainImageUrl ?? '',
            name: place.name,
            countText: place.tourCount == 1
                ? '1 tour'
                : '${place.tourCount} tours',
            onTap: () => _openTourWithPlace(place),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // ------------------------------------------------------------------
          // HOME BANNER
          // ------------------------------------------------------------------
          SliverToBoxAdapter(
            child: _HomeBanner(
              onNotifications: widget.onNotifications,
              onProfile: widget.onProfile,
            ),
          ),

          // ------------------------------------------------------------------
          // SEARCH
          // ------------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: _SearchBar(onTap: widget.onSearch),
            ),
          ),

          // ------------------------------------------------------------------
          // QUICK ACTIONS
          // ------------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onCheckout,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Checkout & Pay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onReview,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: primaryGreen, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outline_rounded,
                              color: primaryGreen,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rate & Review',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // TRENDING PLACES TITLE
          // ------------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 19)),

                  const SizedBox(width: 6),

                  const Expanded(
                    child: Text(
                      'Trending Places',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: widget.onSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(width: 2),

                          Icon(
                            Icons.chevron_right,
                            size: 17,
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // TRENDING PLACES
          // ------------------------------------------------------------------
          SliverToBoxAdapter(child: _buildTopTourPlaces()),

          // ------------------------------------------------------------------
          // COMMUNITY STORIES TITLE
          // ------------------------------------------------------------------
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: primaryGreen, size: 20),

                  SizedBox(width: 7),

                  Text(
                    'Community Stories',
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: CommunityFeed(
              key: ValueKey(_feedKey),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 25),
              showHeader: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HOME BANNER
// ============================================================================

class _HomeBanner extends StatelessWidget {
  static const Color darkGreen = Color(0xFF103F2D);
  static const Color primaryGreen = Color(0xFF176B45);

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _HomeBanner({required this.onNotifications, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ------------------------------------------------------------------
          // BANNER IMAGE
          // ------------------------------------------------------------------
          Image.asset(
            'assets/images/home_banner.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ------------------------------------------------------------------
          // SOFT OVERLAY
          // ------------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.10),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // HEADER
          // ------------------------------------------------------------------
          Positioned(
            top: 14,
            left: 18,
            right: 18,
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/historia_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 8),

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIA',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),

                    Text(
                      'EXPLORE • WALK • BELONG',
                      style: TextStyle(
                        color: Color(0xFF60746A),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                _HeaderCircleButton(
                  icon: Icons.notifications_none_rounded,
                  showDot: true,
                  onTap: onNotifications,
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: onProfile,
                  child: Container(
                    width: 41,
                    height: 41,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/profile_2.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return const Icon(Icons.person, color: primaryGreen);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // MAIN BANNER TITLE
          // ------------------------------------------------------------------
          const Positioned(
            left: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 24,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Sri Lanka’s Heritage',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 26,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'Ancient stories. Timeless beauty.',
                  style: TextStyle(
                    color: Color(0xFF596B62),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

// ============================================================================
// HEADER CIRCLE BUTTON
// ============================================================================

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(icon, color: const Color(0xFF174D37), size: 22)),

            if (showDot)
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF543D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SEARCH BAR
// ============================================================================

class _SearchBar extends StatelessWidget {
  static const Color primaryGreen = Color(0xFF176B45);

  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFD6DDD8)),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 25, color: Color(0xFF26372F)),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Search Historical Place',
                  style: TextStyle(
                    color: Color(0xFF69736E),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              Icon(Icons.tune_rounded, color: primaryGreen, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopPlacesMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _TopPlacesMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7E3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF176B45), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF69736E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ============================================================================
// TRENDING PLACE CARD
// ============================================================================

class _TrendingPlaceCard extends StatelessWidget {
  final String image;
  final String name;
  final String countText;
  final VoidCallback? onTap;

  const _TrendingPlaceCard({
    required this.image,
    required this.name,
    required this.countText,
    this.onTap,
  });

  bool get _isNetworkImage =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 105,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(),
                ),

                Positioned(
                  left: 7,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          size: 9,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          countText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF26352E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (image.trim().isEmpty) {
      return _placeholderImage();
    }

    if (_isNetworkImage) {
      return Image.network(
        image,
        width: 105,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderImage(),
      );
    }

    return Image.asset(
      image,
      width: 105,
      height: 108,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 105,
      height: 108,
      color: const Color(0xFFE7EEE9),
      child: const Icon(
        Icons.account_balance_outlined,
        color: Color(0xFF176B45),
      ),
    );
  }
}

// ============================================================================
// COMMUNITY POST CARD
// ============================================================================

class _CommunityPostCard extends StatefulWidget {
  final int? postId;
  final String userName;
  final String location;
  final String time;
  final String image;
  final String likes;
  final String comments;
  final String caption;
  final VoidCallback onDeleted;

  const _CommunityPostCard({
    required this.postId,
    required this.userName,
    required this.location,
    required this.time,
    required this.image,
    required this.likes,
    required this.comments,
    required this.caption,
    required this.onDeleted,
  });

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  final PostService _postService = PostService();

  bool liked = false;
  bool saved = false;
  bool deleting = false;

  // --------------------------------------------------------------------------
  // DELETE POST
  // --------------------------------------------------------------------------

  Future<void> _deletePost() async {
    final postId = widget.postId;

    if (postId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to identify this post.'),
            backgroundColor: Colors.red,
          ),
        );

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      setState(() {
        deleting = true;
      });

      // DELETE /api/posts/{id}
      await _postService.deletePost(postId);

      if (!mounted) {
        return;
      }

      // Remove post from the home screen.
      widget.onDeleted();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully.'),
            backgroundColor: Color(0xFF176B45),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        deleting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to delete post.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // --------------------------------------------------------------------------
  // POST IMAGE
  // --------------------------------------------------------------------------

  Widget _buildPostImage() {
    if (widget.image.trim().isEmpty) {
      return _imagePlaceholder();
    }

    // Backend/network image
    if (widget.image.startsWith('http://') ||
        widget.image.startsWith('https://')) {
      return Image.network(
        widget.image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _imagePlaceholder();
        },
      );
    }

    // Local asset image
    return Image.asset(
      widget.image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return _imagePlaceholder();
      },
    );
  }

  // --------------------------------------------------------------------------
  // IMAGE PLACEHOLDER
  // --------------------------------------------------------------------------

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFE6EEE9),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF176B45)),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // USER INFORMATION
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: Color(0xFFE7EEE9),
                  child: Icon(Icons.person, color: Color(0xFF176B45)),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173D2E),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFE5534B),
                            size: 11,
                          ),

                          const SizedBox(width: 2),

                          Flexible(
                            child: Text(
                              widget.time.isEmpty
                                  ? widget.location
                                  : '${widget.location} • ${widget.time}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7B8580),
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ------------------------------------------------------------
                // THREE DOT MENU
                // ------------------------------------------------------------
                deleting
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF176B45),
                          ),
                        ),
                      )
                    : PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: Color(0xFF53645B),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deletePost();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete Post',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // POST IMAGE
          // ------------------------------------------------------------------
          AspectRatio(
            aspectRatio: 1.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPostImage(),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      '1/1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // ACTIONS
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 2),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      liked = !liked;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked
                          ? const Color(0xFFE94747)
                          : const Color(0xFF25362E),
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                Text(
                  widget.likes,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF25362E),
                  ),
                ),

                const SizedBox(width: 15),

                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: Color(0xFF25362E),
                ),

                const SizedBox(width: 5),

                Text(
                  widget.comments,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF25362E),
                  ),
                ),

                const Spacer(),

                InkWell(
                  onTap: () {
                    setState(() {
                      saved = !saved;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 23,
                      color: const Color(0xFF176B45),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // CAPTION
          // ------------------------------------------------------------------
          if (widget.caption.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 3, 15, 15),
              child: Text(
                widget.caption,
                style: const TextStyle(
                  color: Color(0xFF4C5751),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

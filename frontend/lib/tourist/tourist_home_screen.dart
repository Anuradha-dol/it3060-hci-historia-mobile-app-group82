import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../services/post_service.dart';
import '../widgets/historia_components.dart';
import 'create_post_screen.dart';
import 'historical_search_screen.dart';
import 'notifications_screen.dart';

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
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN SEARCH
  // --------------------------------------------------------------------------

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoricalSearchScreen(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // OPEN CREATE POST
  // --------------------------------------------------------------------------

  Future<void> _openCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
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

  // --------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------------------------------

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _openHome();
        break;

      case 1:
        // Tour screen will be connected later.
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

  const _TouristDashboard({
    super.key,
    required this.onNotifications,
    required this.onProfile,
    required this.onSearch,
  });

  @override
  State<_TouristDashboard> createState() => _TouristDashboardState();
}

class _TouristDashboardState extends State<_TouristDashboard> {
  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF123D2D);

  final PostService _postService = PostService();

  List<Map<String, dynamic>> _posts = [];

  bool _loadingPosts = true;

  String? _postsError;

  // --------------------------------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadPosts();
  }

  // --------------------------------------------------------------------------
  // LOAD POSTS FROM BACKEND
  // --------------------------------------------------------------------------

  Future<void> _loadPosts() async {
    if (mounted) {
      setState(() {
        _loadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final posts = await _postService.getAllPosts();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = posts;
        _loadingPosts = false;
        _postsError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingPosts = false;
        _postsError = 'Unable to load community posts.';
      });
    }
  }

  // --------------------------------------------------------------------------
  // FORMAT POST TIME
  // --------------------------------------------------------------------------

  String _formatPostTime(dynamic value) {
    if (value == null) {
      return '';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return '';
    }

    final difference = DateTime.now().difference(date);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // --------------------------------------------------------------------------
  // GET USER NAME
  // --------------------------------------------------------------------------

  String _getUserName(Map<String, dynamic> post) {
    final username = post['username']?.toString();

    if (username != null && username.trim().isNotEmpty) {
      return username;
    }

    final userName = post['userName']?.toString();

    if (userName != null && userName.trim().isNotEmpty) {
      return userName;
    }

    return 'Historia User';
  }

  // --------------------------------------------------------------------------
  // GET HISTORICAL PLACE NAME
  // --------------------------------------------------------------------------

  String _getPlaceName(Map<String, dynamic> post) {
    final placeName = post['historicalPlaceName']?.toString();

    if (placeName != null && placeName.trim().isNotEmpty) {
      return placeName;
    }

    final location = post['location']?.toString();

    if (location != null && location.trim().isNotEmpty) {
      return location;
    }

    return 'Historical Place';
  }

  // --------------------------------------------------------------------------
  // GET FIRST IMAGE URL
  // --------------------------------------------------------------------------

  String _getPostImage(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    final imageUrl = post['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    return '';
  }

  // --------------------------------------------------------------------------
  // GET LIKE COUNT
  // --------------------------------------------------------------------------

  String _getLikeCount(Map<String, dynamic> post) {
    if (post['likeCount'] != null) {
      return post['likeCount'].toString();
    }

    if (post['likes'] != null) {
      return post['likes'].toString();
    }

    return '0';
  }

  // --------------------------------------------------------------------------
  // GET COMMENT COUNT
  // --------------------------------------------------------------------------

  String _getCommentCount(Map<String, dynamic> post) {
    if (post['commentCount'] != null) {
      return post['commentCount'].toString();
    }

    if (post['comments'] is num) {
      return post['comments'].toString();
    }

    return '0';
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadPosts,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
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
              child: _SearchBar(
                onTap: widget.onSearch,
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
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 19),
                  ),

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
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
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

          SliverToBoxAdapter(
            child: SizedBox(
              height: 145,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _TrendingPlaceCard(
                    image: 'assets/images/sigiriya.jpg',
                    name: 'Sigiriya',
                    likes: '1.2K',
                    onTap: widget.onSearch,
                  ),

                  const SizedBox(width: 10),

                  const _TrendingPlaceCard(
                    image: 'assets/images/ruwanwelisaya.jpg',
                    name: 'Ruwanwelisaya',
                    likes: '890',
                  ),

                  const SizedBox(width: 10),

                  const _TrendingPlaceCard(
                    image: 'assets/images/sri_maha_bodhi.jpg',
                    name: 'Sri Maha Bodhi',
                    likes: '756',
                  ),

                  const SizedBox(width: 10),

                  const _TrendingPlaceCard(
                    image: 'assets/images/galle_fort.jpg',
                    name: 'Galle Fort',
                    likes: '642',
                  ),

                  const SizedBox(width: 18),
                ],
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // COMMUNITY STORIES TITLE
          // ------------------------------------------------------------------

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: primaryGreen,
                    size: 20,
                  ),

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

          // ------------------------------------------------------------------
          // LOADING POSTS
          // ------------------------------------------------------------------

          if (_loadingPosts)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                  ),
                ),
              ),
            )

          // ------------------------------------------------------------------
          // ERROR LOADING POSTS
          // ------------------------------------------------------------------

          else if (_postsError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE1E7E3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 36,
                        color: Color(0xFF69736E),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _postsError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF69736E),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton.icon(
                        onPressed: _loadPosts,
                        icon: const Icon(
                          Icons.refresh,
                          color: primaryGreen,
                        ),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ------------------------------------------------------------------
          // NO POSTS
          // ------------------------------------------------------------------

          else if (_posts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 38,
                        color: Color(0xFF69736E),
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No community posts yet.',
                        style: TextStyle(
                          color: Color(0xFF69736E),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Be the first to share an experience!',
                        style: TextStyle(
                          color: Color(0xFF929B96),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ------------------------------------------------------------------
          // POSTS FROM BACKEND
          // ------------------------------------------------------------------

          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];

                  final userName = _getUserName(post);

                  final placeName = _getPlaceName(post);

                  final imageUrl = _getPostImage(post);

                  final caption = post['caption']?.toString() ?? '';

                  final time = _formatPostTime(
                    post['createdAt'],
                  );

                  final likes = _getLikeCount(post);

                  final comments = _getCommentCount(post);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      index == 0 ? 0 : 7,
                      14,
                      index == _posts.length - 1 ? 25 : 7,
                    ),
                    child: _CommunityPostCard(
                      postId: int.tryParse(
                        post['id']?.toString() ?? '',
                      ),
                      userName: userName,
                      location: 'Visited $placeName',
                      time: time,
                      image: imageUrl,
                      likes: likes,
                      comments: comments,
                      caption: caption,
                      onDeleted: () {
                        setState(() {
                          _posts.removeWhere(
                            (item) =>
                                item['id']?.toString() ==
                                post['id']?.toString(),
                          );
                        });
                      },
                    ),
                  );
                },
                childCount: _posts.length,
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

  const _HomeBanner({
    required this.onNotifications,
    required this.onProfile,
  });

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
                stops: const [
                  0.0,
                  0.45,
                  1.0,
                ],
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
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person,
                            color: primaryGreen,
                          );
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
            Center(
              child: Icon(
                icon,
                color: const Color(0xFF174D37),
                size: 22,
              ),
            ),

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

  const _SearchBar({
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFD6DDD8),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 25,
                color: Color(0xFF26372F),
              ),

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

              Icon(
                Icons.tune_rounded,
                color: primaryGreen,
                size: 22,
              ),
            ],
          ),
        ),
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
  final String likes;
  final VoidCallback? onTap;

  const _TrendingPlaceCard({
    required this.image,
    required this.name,
    required this.likes,
    this.onTap,
  });

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
                  child: Image.asset(
                    image,
                    width: 105,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 105,
                        height: 108,
                        color: const Color(0xFFE7EEE9),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          color: Color(0xFF176B45),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF523C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 10,
                        ),

                        SizedBox(width: 2),

                        Text(
                          'Trending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          Icons.favorite,
                          size: 9,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          likes,
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
  State<_CommunityPostCard> createState() =>
      _CommunityPostCardState();
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
            content: Text(
              'Unable to identify this post.',
            ),
            backgroundColor: Colors.red,
          ),
        );

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post',
          ),
          content: const Text(
            'Are you sure you want to delete this post?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
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
      await _postService.deletePost(
        postId,
      );

      if (!mounted) {
        return;
      }

      // Remove post from the home screen.
      widget.onDeleted();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Post deleted successfully.',
            ),
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
            content: Text(
              'Unable to delete post.',
            ),
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
        errorBuilder: (_, __, ___) {
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
      errorBuilder: (_, __, ___) {
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
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFF176B45),
        ),
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
        border: Border.all(
          color: const Color(0xFFE1E7E3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
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
                  backgroundColor: Color(
                    0xFFE7EEE9,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Color(
                      0xFF176B45,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(
                            0xFF173D2E,
                          ),
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(
                              0xFFE5534B,
                            ),
                            size: 11,
                          ),

                          const SizedBox(
                            width: 2,
                          ),

                          Flexible(
                            child: Text(
                              widget.time.isEmpty
                                  ? widget.location
                                  : '${widget.location} • ${widget.time}',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color: Color(
                                  0xFF7B8580,
                                ),
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
                        padding:
                            EdgeInsets.all(
                          10,
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(
                              0xFF176B45,
                            ),
                          ),
                        ),
                      )
                    : PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: Color(
                            0xFF53645B,
                          ),
                        ),
                        onSelected: (value) {
                          if (value ==
                              'delete') {
                            _deletePost();
                          }
                        },
                        itemBuilder:
                            (context) => [
                          const PopupMenuItem<
                              String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                      Colors.red,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Delete Post',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.red,
                                    fontWeight:
                                        FontWeight
                                            .w600,
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
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Text(
                      '1/1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w700,
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
            padding:
                const EdgeInsets.fromLTRB(
              11,
              8,
              11,
              2,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      liked = !liked;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      4,
                    ),
                    child: Icon(
                      liked
                          ? Icons.favorite
                          : Icons
                              .favorite_border,
                      color: liked
                          ? const Color(
                              0xFFE94747,
                            )
                          : const Color(
                              0xFF25362E,
                            ),
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 2,
                ),

                Text(
                  widget.likes,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color: Color(
                      0xFF25362E,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 15,
                ),

                const Icon(
                  Icons
                      .chat_bubble_outline_rounded,
                  size: 20,
                  color: Color(
                    0xFF25362E,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  widget.comments,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color: Color(
                      0xFF25362E,
                    ),
                  ),
                ),

                const Spacer(),

                InkWell(
                  onTap: () {
                    setState(() {
                      saved = !saved;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      4,
                    ),
                    child: Icon(
                      saved
                          ? Icons.bookmark
                          : Icons
                              .bookmark_border,
                      size: 23,
                      color: const Color(
                        0xFF176B45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // CAPTION
          // ------------------------------------------------------------------

          if (widget.caption
              .trim()
              .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                15,
                3,
                15,
                15,
              ),
              child: Text(
                widget.caption,
                style: const TextStyle(
                  color: Color(
                    0xFF4C5751,
                  ),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            )
          else
            const SizedBox(
              height: 10,
            ),
        ],
      ),
    );
  }
}
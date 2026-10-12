import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/historical_place_model.dart';
import '../profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/historia_bottom_nav.dart';
import 'buddy_chat_screen.dart';
import 'create_post_screen.dart';
import 'historical_search_screen.dart';
import 'tour_planner_screen.dart';

class BuddyMatchModel {
  final int userId;
  final String username;
  final String? profileImageUrl;
  final bool online;
  final int tourId;
  final String tourTitle;
  final String tourDate;
  final int historicalPlaceId;
  final String historicalPlaceName;

  const BuddyMatchModel({
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.online,
    required this.tourId,
    required this.tourTitle,
    required this.tourDate,
    required this.historicalPlaceId,
    required this.historicalPlaceName,
  });

  factory BuddyMatchModel.fromJson(Map<String, dynamic> json) {
    return BuddyMatchModel(
      userId: (json['userId'] as num).toInt(),
      username: json['username']?.toString() ?? 'Tourist',
      profileImageUrl: json['profileImageUrl']?.toString(),
      online: json['online'] == true,
      tourId: (json['tourId'] as num).toInt(),
      tourTitle: json['tourTitle']?.toString() ?? '',
      tourDate: json['tourDate']?.toString() ?? '',
      historicalPlaceId: (json['historicalPlaceId'] as num).toInt(),
      historicalPlaceName: json['historicalPlaceName']?.toString() ?? '',
    );
  }
}

class BuddyRequestModel {
  final int id;
  final int senderId;
  final String senderUsername;
  final String? senderProfileImageUrl;
  final bool senderOnline;
  final int receiverId;
  final String receiverUsername;
  final String? receiverProfileImageUrl;
  final bool receiverOnline;
  final int tourId;
  final int historicalPlaceId;
  final String historicalPlaceName;
  final String status;
  final String? createdAt;

  const BuddyRequestModel({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImageUrl,
    required this.senderOnline,
    required this.receiverId,
    required this.receiverUsername,
    this.receiverProfileImageUrl,
    required this.receiverOnline,
    required this.tourId,
    required this.historicalPlaceId,
    required this.historicalPlaceName,
    required this.status,
    this.createdAt,
  });

  factory BuddyRequestModel.fromJson(Map<String, dynamic> json) {
    return BuddyRequestModel(
      id: (json['id'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      senderUsername: json['senderUsername']?.toString() ?? 'Tourist',
      senderProfileImageUrl: json['senderProfileImageUrl']?.toString(),
      senderOnline: json['senderOnline'] == true,
      receiverId: (json['receiverId'] as num).toInt(),
      receiverUsername: json['receiverUsername']?.toString() ?? 'Tourist',
      receiverProfileImageUrl: json['receiverProfileImageUrl']?.toString(),
      receiverOnline: json['receiverOnline'] == true,
      tourId: (json['tourId'] as num).toInt(),
      historicalPlaceId: (json['historicalPlaceId'] as num).toInt(),
      historicalPlaceName: json['historicalPlaceName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class BuddyConversationModel {
  final int requestId;
  final int otherUserId;
  final String username;
  final String? profileImageUrl;
  final bool online;
  final String historicalPlaceName;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  const BuddyConversationModel({
    required this.requestId,
    required this.otherUserId,
    required this.username,
    this.profileImageUrl,
    required this.online,
    required this.historicalPlaceName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory BuddyConversationModel.fromJson(Map<String, dynamic> json) {
    return BuddyConversationModel(
      requestId: (json['requestId'] as num).toInt(),
      otherUserId: (json['otherUserId'] as num).toInt(),
      username: json['username']?.toString() ?? 'Tourist',
      profileImageUrl: json['profileImageUrl']?.toString(),
      online: json['online'] == true,
      historicalPlaceName: json['historicalPlaceName']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString(),
      lastMessageTime: json['lastMessageTime']?.toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class BuddyApiService {
  final Dio _dio = ApiService.instance.dio;

  Future<List<HistoricalPlaceModel>> getHistoricalPlaces() async {
    final response = await _dio.get(ApiConfig.historicalPlaces);
    return _readList(response, HistoricalPlaceModel.fromJson);
  }

  Future<List<BuddyMatchModel>> findBuddies({
    required int placeId,
    required String date,
  }) async {
    final response = await _dio.get(
      '/api/buddies/search',
      queryParameters: {'placeId': placeId, 'date': date},
    );

    return _readList(response, BuddyMatchModel.fromJson);
  }

  Future<BuddyRequestModel> sendBuddyRequest({
    required int receiverId,
    required int receiverTourId,
    required int placeId,
    required String date,
  }) async {
    final response = await _dio.post(
      '/api/buddies/requests',
      queryParameters: {
        'receiverId': receiverId,
        'receiverTourId': receiverTourId,
        'placeId': placeId,
        'date': date,
      },
    );

    return BuddyRequestModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<BuddyRequestModel>> getReceivedRequests() async {
    final response = await _dio.get('/api/buddies/requests/received');
    return _readList(response, BuddyRequestModel.fromJson);
  }

  Future<List<BuddyRequestModel>> getSentRequests() async {
    final response = await _dio.get('/api/buddies/requests/sent');
    return _readList(response, BuddyRequestModel.fromJson);
  }

  Future<BuddyRequestModel> acceptRequest(int requestId) async {
    final response = await _dio.put('/api/buddies/requests/$requestId/accept');

    return BuddyRequestModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> rejectRequest(int requestId) async {
    await _dio.put('/api/buddies/requests/$requestId/reject');
  }

  Future<List<BuddyConversationModel>> getConversations() async {
    final response = await _dio.get('/api/buddies/conversations');
    return _readList(response, BuddyConversationModel.fromJson);
  }

  List<T> _readList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => mapper(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

class TravelBuddyScreen extends StatefulWidget {
  const TravelBuddyScreen({super.key});

  @override
  State<TravelBuddyScreen> createState() => _TravelBuddyScreenState();
}

class _TravelBuddyScreenState extends State<TravelBuddyScreen> {
  static const Color background = Color(0xFFF8FAF7);
  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF123D2D);
  static const Color gold = Color(0xFFD4AB58);

  final BuddyApiService _api = BuddyApiService();
  final StorageService _storage = StorageService();
  final TextEditingController _placeController = TextEditingController();

  String? _token;
  int? _currentUserId;

  List<HistoricalPlaceModel> _places = [];
  List<BuddyMatchModel> _matches = [];
  List<BuddyRequestModel> _receivedRequests = [];
  List<BuddyRequestModel> _sentRequests = [];
  List<BuddyConversationModel> _conversations = [];

  HistoricalPlaceModel? _selectedPlace;
  DateTime? _selectedDate;

  bool _booting = true;
  bool _loadingPlaces = true;
  bool _searching = false;
  bool _loadingRequests = true;
  bool _loadingChats = true;
  int? _requestingUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final user = context.read<AuthProvider>().user;
    final token = await _storage.getAccessToken();

    if (!mounted) {
      return;
    }

    setState(() {
      _token = token;
      _currentUserId = user?.id;
      _booting = false;
    });

    await Future.wait([_loadPlaces(), _loadRequests(), _loadChats()]);
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loadingPlaces = true;
    });

    try {
      final places = await _api.getHistoricalPlaces();

      if (!mounted) {
        return;
      }

      setState(() {
        _places = places;
        _loadingPlaces = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingPlaces = false;
      });

      _showError(error);
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loadingRequests = true;
    });

    try {
      final results = await Future.wait([
        _api.getReceivedRequests(),
        _api.getSentRequests(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _receivedRequests = results[0];
        _sentRequests = results[1];
        _loadingRequests = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRequests = false;
      });
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _loadingChats = true;
    });

    try {
      final conversations = await _api.getConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
        _loadingChats = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingChats = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _findBuddies() async {
    final place = _selectedPlace;
    final date = _selectedDate;

    if (place == null) {
      _showMessage('Select a historical place.', error: true);
      return;
    }

    if (date == null) {
      _showMessage('Select a travel date.', error: true);
      return;
    }

    setState(() {
      _searching = true;
      _matches = [];
    });

    try {
      final matches = await _api.findBuddies(
        placeId: place.id,
        date: _apiDate(date),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _matches = matches;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searching = false;
      });

      _showError(error);
    }
  }

  Future<void> _sendRequest(BuddyMatchModel buddy) async {
    final place = _selectedPlace;
    final date = _selectedDate;

    if (place == null || date == null) {
      return;
    }

    setState(() {
      _requestingUserId = buddy.userId;
    });

    try {
      await _api.sendBuddyRequest(
        receiverId: buddy.userId,
        receiverTourId: buddy.tourId,
        placeId: place.id,
        date: _apiDate(date),
      );

      await _loadRequests();

      if (!mounted) {
        return;
      }

      _showMessage('Request sent to ${buddy.username}.');
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _requestingUserId = null;
        });
      }
    }
  }

  Future<void> _acceptRequest(BuddyRequestModel request) async {
    try {
      final accepted = await _api.acceptRequest(request.id);

      await _loadRequests();
      await _loadChats();

      if (!mounted) {
        return;
      }

      _showMessage('Buddy request accepted.');

      await _openChatFromRequest(accepted);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _rejectRequest(BuddyRequestModel request) async {
    try {
      await _api.rejectRequest(request.id);
      await _loadRequests();
      _showMessage('Buddy request rejected.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openChatFromRequest(BuddyRequestModel request) {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      _showMessage('Please log in again.', error: true);
      return Future.value();
    }

    final iAmSender = request.senderId == currentUserId;

    return _openChat(
      requestId: request.id,
      otherUserId: iAmSender ? request.receiverId : request.senderId,
      username: iAmSender ? request.receiverUsername : request.senderUsername,
      profileImageUrl: iAmSender
          ? request.receiverProfileImageUrl
          : request.senderProfileImageUrl,
      otherOnline: iAmSender ? request.receiverOnline : request.senderOnline,
    );
  }

  Future<void> _openChat({
    required int requestId,
    required int otherUserId,
    required String username,
    String? profileImageUrl,
    required bool otherOnline,
  }) async {
    final token = _token;
    final currentUserId = _currentUserId;

    if (token == null || currentUserId == null) {
      _showMessage('Please log in again.', error: true);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuddyChatScreen(
          token: token,
          currentUserId: currentUserId,
          requestId: requestId,
          otherUserId: otherUserId,
          username: username,
          profileImageUrl: profileImageUrl,
          otherOnline: otherOnline,
        ),
      ),
    );

    _loadChats();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TourPlannerScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoricalSearchScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: darkGreen,
          elevation: 0,
          titleSpacing: 0,
          title: const Text(
            'Travel Buddy',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            indicatorColor: gold,
            labelColor: darkGreen,
            unselectedLabelColor: Color(0xFF748079),
            tabs: [
              Tab(icon: Icon(Icons.travel_explore_rounded), text: 'Find'),
              Tab(icon: Icon(Icons.person_add_alt_rounded), text: 'Requests'),
              Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Chats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildFindTab(), _buildRequestsTab(), _buildChatsTab()],
        ),
        bottomNavigationBar: HistoriaBottomNavigation(
          currentIndex: 0,
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
      ),
    );
  }

  Widget _buildFindTab() {
    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadPlaces,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _sectionHeader(
            icon: Icons.group_add_rounded,
            title: 'Find tourists',
            subtitle:
                'Search by place and date to find tourists visiting the same historical site.',
          ),
          const SizedBox(height: 14),
          _searchCard(),
          const SizedBox(height: 18),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(top: 45),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_matches.isEmpty)
            _emptyState(
              icon: Icons.travel_explore_rounded,
              title: 'No matching tourists yet',
              subtitle: 'Choose a place and date, then tap Find Buddies.',
            )
          else
            ..._matches.map(
              (buddy) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuddyMatchCard(
                  buddy: buddy,
                  requesting: _requestingUserId == buddy.userId,
                  onRequest: () => _sendRequest(buddy),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (_loadingPlaces)
            const SizedBox(
              height: 54,
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else
            Autocomplete<HistoricalPlaceModel>(
              displayStringForOption: (place) => place.name,
              optionsBuilder: (textValue) {
                final query = textValue.text.trim().toLowerCase();

                if (query.isEmpty) {
                  return _places.take(20);
                }

                return _places.where(
                  (place) => place.name.toLowerCase().contains(query),
                );
              },
              onSelected: (place) {
                setState(() {
                  _selectedPlace = place;
                  _placeController.text = place.name;
                });
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onSubmitted) {
                    if (_placeController.text != textController.text) {
                      textController.text = _placeController.text;
                    }

                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        _placeController.text = value;

                        final exactMatch = _places.where(
                          (place) =>
                              place.name.toLowerCase() ==
                              value.trim().toLowerCase(),
                        );

                        setState(() {
                          _selectedPlace = exactMatch.isEmpty
                              ? null
                              : exactMatch.first;
                        });
                      },
                      decoration: _fieldDecoration(
                        label: 'Historical place',
                        hint: 'Type a place name',
                        icon: Icons.location_on_outlined,
                      ),
                    );
                  },
            ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: _fieldDecoration(
                label: 'Travel date',
                hint: 'Select date',
                icon: Icons.calendar_month_outlined,
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select date'
                    : _displayDate(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null
                      ? const Color(0xFF839089)
                      : const Color(0xFF213F34),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _searching ? null : _findBuddies,
              icon: const Icon(Icons.search_rounded),
              label: Text(_searching ? 'Searching...' : 'Find Buddies'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: const Color(0xFF97B7A4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_loadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    final pendingReceived = _receivedRequests
        .where((request) => request.status == 'PENDING')
        .toList();
    final activeReceived = _receivedRequests
        .where((request) => request.status != 'PENDING')
        .toList();

    if (_receivedRequests.isEmpty && _sentRequests.isEmpty) {
      return RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            _emptyState(
              icon: Icons.person_add_alt_rounded,
              title: 'No buddy requests',
              subtitle: 'Incoming and sent requests will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadRequests,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          if (pendingReceived.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.mark_email_unread_outlined,
              title: 'Incoming requests',
              subtitle: 'Accept a request to open a private real-time chat.',
            ),
            const SizedBox(height: 12),
            ...pendingReceived.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuddyRequestCard(
                  request: request,
                  currentUserId: _currentUserId,
                  incoming: true,
                  onAccept: () => _acceptRequest(request),
                  onReject: () => _rejectRequest(request),
                  onChat: () => _openChatFromRequest(request),
                ),
              ),
            ),
          ],
          if (activeReceived.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.archive_outlined,
              title: 'Received history',
              subtitle: 'Accepted and rejected received requests.',
            ),
            const SizedBox(height: 12),
            ...activeReceived.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuddyRequestCard(
                  request: request,
                  currentUserId: _currentUserId,
                  incoming: true,
                  onAccept: () => _acceptRequest(request),
                  onReject: () => _rejectRequest(request),
                  onChat: () => _openChatFromRequest(request),
                ),
              ),
            ),
          ],
          if (_sentRequests.isNotEmpty) ...[
            _sectionHeader(
              icon: Icons.send_outlined,
              title: 'Sent requests',
              subtitle: 'When accepted, the chat appears in your inbox.',
            ),
            const SizedBox(height: 12),
            ..._sentRequests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BuddyRequestCard(
                  request: request,
                  currentUserId: _currentUserId,
                  incoming: false,
                  onAccept: () => _acceptRequest(request),
                  onReject: () => _rejectRequest(request),
                  onChat: () => _openChatFromRequest(request),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_loadingChats) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (_conversations.isEmpty) {
      return RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadChats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            _emptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'Accepted travel buddy chats will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadChats,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) {
          return const Divider(height: 1, indent: 82);
        },
        itemBuilder: (context, index) {
          final conversation = _conversations[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: _avatar(
              imageUrl: conversation.profileImageUrl,
              name: conversation.username,
              radius: 28,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (conversation.lastMessageTime != null)
                  Text(
                    _formatInboxTime(conversation.lastMessageTime!),
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? primaryGreen
                          : const Color(0xFF8B9690),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ??
                              conversation.historicalPlaceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? const Color(0xFF223A30)
                                : const Color(0xFF76827B),
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _PresenceBadge(online: conversation.online),
                ],
              ),
            ),
            onTap: () {
              _openChat(
                requestId: conversation.requestId,
                otherUserId: conversation.otherUserId,
                username: conversation.username,
                profileImageUrl: conversation.profileImageUrl,
                otherOnline: conversation.online,
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F2EA),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryGreen, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF75837B),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 34),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 56, color: const Color(0xFF9EB8A9)),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF78867E),
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: const Color(0xFFF7FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE8E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE8E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDDE8E1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x09093829),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatInboxTime(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }

      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  void _showError(Object error) {
    _showMessage(ApiService.instance.getErrorMessage(error), error: true);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : primaryGreen,
        ),
      );
  }
}

class _BuddyMatchCard extends StatelessWidget {
  final BuddyMatchModel buddy;
  final bool requesting;
  final VoidCallback onRequest;

  const _BuddyMatchCard({
    required this.buddy,
    required this.requesting,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _avatar(
            imageUrl: buddy.profileImageUrl,
            name: buddy.username,
            radius: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buddy.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF183D2E),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  buddy.historicalPlaceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF68766E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                _PresenceBadge(online: buddy.online),
                if (buddy.tourTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    buddy.tourTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF88958E),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: requesting ? null : onRequest,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF176B45),
              disabledBackgroundColor: const Color(0xFF9DBAA8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(requesting ? 'Sending' : 'Request'),
          ),
        ],
      ),
    );
  }
}

class _BuddyRequestCard extends StatelessWidget {
  final BuddyRequestModel request;
  final int? currentUserId;
  final bool incoming;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChat;

  const _BuddyRequestCard({
    required this.request,
    required this.currentUserId,
    required this.incoming,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = incoming
        ? request.senderUsername
        : request.receiverUsername;
    final imageUrl = incoming
        ? request.senderProfileImageUrl
        : request.receiverProfileImageUrl;
    final otherOnline = incoming
        ? request.senderOnline
        : request.receiverOnline;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(imageUrl: imageUrl, name: otherName, radius: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF183D2E),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.historicalPlaceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6E7B74),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _PresenceBadge(online: otherOnline),
                  ],
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          if (incoming && request.status == 'PENDING') ...[
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF176B45),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (request.status == 'ACCEPTED') ...[
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Open Chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF123D2D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACCEPTED' => const Color(0xFF176B45),
      'REJECTED' => const Color(0xFFC7473F),
      _ => const Color(0xFFE3A331),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PresenceBadge extends StatelessWidget {
  final bool online;

  const _PresenceBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF176B45) : const Color(0xFF8A9590);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          online ? 'Online' : 'Offline',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

Widget _avatar({
  required String? imageUrl,
  required String name,
  required double radius,
}) {
  final resolvedImage = ApiConfig.resolveImageUrl(imageUrl);

  if (resolvedImage.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFDDE8E0),
      backgroundImage: NetworkImage(resolvedImage),
    );
  }

  final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFDDE8E0),
    child: Text(
      letter,
      style: TextStyle(
        color: const Color(0xFF173D31),
        fontWeight: FontWeight.w900,
        fontSize: radius * 0.62,
      ),
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFDDE8E1)),
    boxShadow: const [
      BoxShadow(color: Color(0x09093829), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
}

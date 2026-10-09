import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/post_service.dart';

class CommunityFeed extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final bool showHeader;
  final VoidCallback? onCreatePost;

  const CommunityFeed({
    super.key,
    this.padding = EdgeInsets.zero,
    this.showHeader = true,
    this.onCreatePost,
  });

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed> {
  static const Color primaryGreen = Color(0xFF176B45);

  final _postService = PostService();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts({bool showSpinner = true}) async {
    if (mounted && showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final posts = await _postService.getAllPosts();

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  Future<void> _likePost(int index) async {
    final postId = _postId(_posts[index]);

    if (postId == null) return;

    try {
      final updated = await _postService.likePost(postId);

      if (!mounted) return;

      setState(() {
        _posts[index] = updated;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  Future<void> _deletePost(int index) async {
    final post = _posts[index];
    final postId = _postId(post);
    final currentUserId = context.read<AuthProvider>().user?.id;

    if (postId == null) return;

    if (!_isOwnPost(post, currentUserId)) {
      _showMessage('You can only delete your own posts.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post'),
          content: const Text('Do you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _postService.deletePost(postId);

      if (!mounted) return;

      setState(() {
        _posts.removeAt(index);
      });

      _showMessage('Post deleted.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  Future<void> _openComments(Map<String, dynamic> post) async {
    final postId = _postId(post);

    if (postId == null) return;

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return _CommentsSheet(postId: postId, placeName: _placeName(post));
      },
    );

    if (changed == true) {
      await _loadPosts(showSpinner: false);
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

  int? _postId(Map<String, dynamic> post) {
    return int.tryParse(post['id']?.toString() ?? '');
  }

  bool _isOwnPost(Map<String, dynamic> post, int? currentUserId) {
    if (currentUserId == null) {
      return false;
    }

    final postUserId = int.tryParse(post['userId']?.toString() ?? '');

    return postUserId == currentUserId;
  }

  String _username(Map<String, dynamic> post) {
    final value = post['username']?.toString().trim();
    return value == null || value.isEmpty ? 'Historia User' : value;
  }

  String _role(Map<String, dynamic> post) {
    final value = post['userRole']?.toString().trim();
    return value == null || value.isEmpty ? 'USER' : value;
  }

  String _placeName(Map<String, dynamic> post) {
    final value = post['historicalPlaceName']?.toString().trim();
    return value == null || value.isEmpty ? 'Historical Place' : value;
  }

  String _caption(Map<String, dynamic> post) {
    return post['caption']?.toString() ?? '';
  }

  int _number(Map<String, dynamic> post, String key) {
    return int.tryParse(post[key]?.toString() ?? '') ?? 0;
  }

  List<String> _images(Map<String, dynamic> post) {
    final imageUrls = post['imageUrls'];

    if (imageUrls is List) {
      return imageUrls
          .map((item) => item.toString())
          .map(ApiConfig.resolveImageUrl)
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    final imageUrl = post['imageUrl']?.toString();

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return [ApiConfig.resolveImageUrl(imageUrl)];
    }

    return const [];
  }

  String _timeAgo(Map<String, dynamic> post) {
    final value = post['createdAt'];

    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) _header(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (_error != null)
            _stateBox(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load posts',
              message: _error!,
              actionText: 'Try Again',
              onAction: _loadPosts,
            )
          else if (_posts.isEmpty)
            _stateBox(
              icon: Icons.photo_library_outlined,
              title: 'No community posts yet',
              message: 'Share the first heritage story.',
              actionText: widget.onCreatePost == null ? null : 'Create Post',
              onAction: widget.onCreatePost,
            )
          else
            ...List.generate(_posts.length, (index) {
              final post = _posts[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _posts.length - 1 ? 0 : 14,
                ),
                child: _PostCard(
                  canDelete: _isOwnPost(post, currentUserId),
                  username: _username(post),
                  role: _role(post),
                  placeName: _placeName(post),
                  caption: _caption(post),
                  images: _images(post),
                  likeCount: _number(post, 'likeCount'),
                  commentCount: _number(post, 'commentCount'),
                  timeAgo: _timeAgo(post),
                  onLike: () => _likePost(index),
                  onComment: () => _openComments(post),
                  onDelete: () => _deletePost(index),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Feed',
                  style: TextStyle(
                    color: Color(0xFF173D2E),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Posts from tourists, guides, and admins.',
                  style: TextStyle(color: Color(0xFF738078), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh posts',
            onPressed: _loadPosts,
            icon: const Icon(Icons.refresh, color: primaryGreen),
          ),
          if (widget.onCreatePost != null)
            FilledButton.icon(
              onPressed: widget.onCreatePost,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Post'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stateBox({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7E3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF69736E), size: 34),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173D2E),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF69736E), fontSize: 12),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionText)),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final bool canDelete;
  final String username;
  final String role;
  final String placeName;
  final String caption;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final String timeAgo;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.canDelete,
    required this.username,
    required this.role,
    required this.placeName,
    required this.caption,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.timeAgo,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE7EEE9),
                  child: Icon(Icons.person, color: Color(0xFF176B45)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173D2E),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.role} - ${widget.placeName}'
                        '${widget.timeAgo.isEmpty ? '' : ' - ${widget.timeAgo}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8580),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF53645B),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        widget.onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _image(),
                if (widget.images.length > 1)
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
                      child: Text(
                        '1/${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _liked = true;
                    });
                    widget.onLike();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? Colors.red : const Color(0xFF25362E),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.likeCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 18),
                InkWell(
                  onTap: widget.onComment,
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25362E),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.commentCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (widget.caption.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text(
                widget.caption,
                style: const TextStyle(
                  color: Color(0xFF4C5751),
                  fontSize: 12,
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

  Widget _image() {
    if (widget.images.isEmpty) {
      return _placeholder();
    }

    final image = ApiConfig.resolveImageUrl(widget.images.first);

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE6EEE9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Color(0xFF176B45),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final int postId;
  final String placeName;

  const _CommentsSheet({required this.postId, required this.placeName});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primaryGreen = Color(0xFF176B45);

  final _postService = PostService();
  final _controller = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _postService.getComments(widget.postId);

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = ApiService.instance.getErrorMessage(e);
      });
    }
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      final comment = await _postService.addComment(
        postId: widget.postId,
        commentText: text,
      );

      if (!mounted) return;

      setState(() {
        _comments.add(comment);
        _controller.clear();
        _sending = false;
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage(ApiService.instance.getErrorMessage(e), error: true);
    }
  }

  Future<void> _likeComment(int index) async {
    final commentId = int.tryParse(_comments[index]['id']?.toString() ?? '');

    if (commentId == null) return;

    try {
      final updated = await _postService.likeComment(
        postId: widget.postId,
        commentId: commentId,
      );

      if (!mounted) return;

      setState(() {
        _comments[index] = updated;
      });
    } catch (e) {
      if (!mounted) return;
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
    final media = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: media.size.height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                              color: Color(0xFF173D2E),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF738078),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, _changed),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _body()),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write a comment',
                          filled: true,
                          fillColor: const Color(0xFFF5F8F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _addComment,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF69736E)),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'No comments yet.',
          style: TextStyle(color: Color(0xFF69736E)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final username = comment['username']?.toString() ?? 'Historia User';
        final text = comment['commentText']?.toString() ?? '';
        final likes = int.tryParse(comment['likeCount']?.toString() ?? '') ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF7),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE1E7E3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFE7EEE9),
                child: Icon(Icons.person, color: primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Color(0xFF173D2E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF4C5751),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _likeComment(index),
                icon: const Icon(Icons.favorite_border, size: 16),
                label: Text(likes.toString()),
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/api_config.dart';
import '../services/api_service.dart';

class BuddyMessageModel {
  final int? id;
  final int senderId;
  final String senderUsername;
  final String message;
  final String sentAt;
  final bool read;

  const BuddyMessageModel({
    this.id,
    required this.senderId,
    required this.senderUsername,
    required this.message,
    required this.sentAt,
    required this.read,
  });

  factory BuddyMessageModel.fromJson(Map<String, dynamic> json) {
    return BuddyMessageModel(
      id: (json['id'] as num?)?.toInt(),
      senderId: (json['senderId'] as num).toInt(),
      senderUsername: json['senderUsername']?.toString() ?? 'Tourist',
      message: json['message']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? '',
      read: json['read'] == true,
    );
  }

  BuddyMessageModel copyWith({bool? read}) {
    return BuddyMessageModel(
      id: id,
      senderId: senderId,
      senderUsername: senderUsername,
      message: message,
      sentAt: sentAt,
      read: read ?? this.read,
    );
  }
}

class BuddyChatScreen extends StatefulWidget {
  final String token;
  final int currentUserId;
  final int requestId;
  final int otherUserId;
  final String username;
  final String? profileImageUrl;
  final bool otherOnline;

  const BuddyChatScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.requestId,
    required this.otherUserId,
    required this.username,
    this.profileImageUrl,
    required this.otherOnline,
  });

  @override
  State<BuddyChatScreen> createState() => _BuddyChatScreenState();
}

class _BuddyChatScreenState extends State<BuddyChatScreen> {
  static const Color background = Color(0xFFEDEFE9);
  static const Color primaryGreen = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF173D31);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<BuddyMessageModel> _messages = [];
  StompClient? _stompClient;
  Timer? _pollTimer;
  Timer? _presenceTimer;

  bool _loading = true;
  bool _socketConnected = false;
  bool _sending = false;
  late bool _otherOnline;

  @override
  void initState() {
    super.initState();
    _otherOnline = widget.otherOnline;
    _loadMessages();
    _loadPresence();
    _connectWebSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!_socketConnected) {
        _loadMessages(silent: true);
      }
    });
    _presenceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadPresence();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _presenceTimer?.cancel();
    _stompClient?.deactivate();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPresence() async {
    try {
      final response = await ApiService.instance.dio.get(
        '/api/buddies/conversations',
      );

      final data = response.data;

      if (data is! List) {
        return;
      }

      for (final item in data) {
        final conversation = Map<String, dynamic>.from(item as Map);
        final requestId = (conversation['requestId'] as num?)?.toInt();

        if (requestId != widget.requestId) {
          continue;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _otherOnline = conversation['online'] == true;
        });

        return;
      }
    } catch (_) {
      // Presence refresh is best effort.
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final response = await ApiService.instance.dio.get(
        '/api/buddies/${widget.requestId}/messages',
      );

      final data = response.data;
      final loaded = data is List
          ? data
                .map(
                  (item) => BuddyMessageModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : <BuddyMessageModel>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = loaded;
        _loading = false;
      });

      await _markMessagesAsRead();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      if (!silent) {
        _showError(error);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await ApiService.instance.dio.put(
        '/api/buddies/${widget.requestId}/read',
      );
    } catch (_) {
      // Best effort only.
    }
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${ApiConfig.baseUrl}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer ${widget.token}'},
        webSocketConnectHeaders: {'Authorization': 'Bearer ${widget.token}'},
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onConnected,
        onWebSocketError: (_) => _setSocketConnected(false),
        onStompError: (_) => _setSocketConnected(false),
        onDisconnect: (_) => _setSocketConnected(false),
      ),
    );

    _stompClient?.activate();
  }

  void _onConnected(StompFrame frame) {
    _setSocketConnected(true);

    _stompClient?.subscribe(
      destination: '/topic/buddies/${widget.requestId}',
      headers: {'Authorization': 'Bearer ${widget.token}'},
      callback: (frame) {
        final body = frame.body;

        if (body == null) {
          return;
        }

        try {
          final decoded = jsonDecode(body);
          final incoming = BuddyMessageModel.fromJson(
            Map<String, dynamic>.from(decoded as Map),
          );

          if (!mounted) {
            return;
          }

          setState(() {
            final alreadyExists =
                incoming.id != null &&
                _messages.any((message) => message.id == incoming.id);

            if (!alreadyExists) {
              _messages.add(incoming);
            }
          });

          if (incoming.senderId != widget.currentUserId) {
            _markMessagesAsRead();
          }

          _scrollToBottom();
        } catch (_) {
          // Ignore malformed frames.
        }
      },
    );

    _stompClient?.subscribe(
      destination: '/topic/buddies/${widget.requestId}/seen',
      headers: {'Authorization': 'Bearer ${widget.token}'},
      callback: (frame) {
        try {
          final decoded = jsonDecode(frame.body ?? '{}');
          final readerId = (decoded['readerId'] as num?)?.toInt();

          if (readerId != widget.otherUserId || !mounted) {
            return;
          }

          setState(() {
            _messages = _messages
                .map(
                  (message) => message.senderId == widget.currentUserId
                      ? message.copyWith(read: true)
                      : message,
                )
                .toList();
          });
        } catch (_) {
          // Ignore malformed frames.
        }
      },
    );

    _markMessagesAsRead();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      if (_stompClient != null && _socketConnected && _stompClient!.connected) {
        _stompClient!.send(
          destination: '/app/buddies/${widget.requestId}/send',
          body: jsonEncode({'message': text}),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'content-type': 'application/json',
          },
        );
      } else {
        final response = await ApiService.instance.dio.post(
          '/api/buddies/${widget.requestId}/messages',
          data: {'message': text},
        );

        final saved = BuddyMessageModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _messages.add(saved);
        });
      }

      _messageController.clear();
      _messageFocusNode.requestFocus();
      _scrollToBottom();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _setSocketConnected(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      _socketConnected = value;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            _avatar(),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _otherOnline ? 'online' : 'offline',
                    style: TextStyle(
                      fontSize: 11,
                      color: _otherOnline
                          ? const Color(0xFFB8F3C7)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  )
                : _messages.isEmpty
                ? _emptyChat()
                : _messageList(),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _emptyChat() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: Colors.black26,
          ),
          SizedBox(height: 12),
          Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final mine = message.senderId == widget.currentUserId;
        return _messageBubble(message, mine);
      },
    );
  }

  Widget _messageBubble(BuddyMessageModel message, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.77,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(12, 9, 9, 6),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFD7F7CF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(mine ? 15 : 4),
            bottomRight: Radius.circular(mine ? 4 : 15),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.message,
              style: const TextStyle(
                color: Color(0xFF1D2622),
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.sentAt),
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
                if (mine) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: message.read
                        ? const Color(0xFF2697D5)
                        : Colors.black38,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 8, 8),
        color: background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.black45,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Material(
              color: primaryGreen,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _sendMessage,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final image = ApiConfig.resolveImageUrl(widget.profileImageUrl);

    if (image.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFDDE8E0),
        backgroundImage: NetworkImage(image),
      );
    }

    final letter = widget.username.trim().isEmpty
        ? '?'
        : widget.username.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFDDE8E0),
      child: Text(
        letter,
        style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w900),
      ),
    );
  }

  String _formatMessageTime(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ApiService.instance.getErrorMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
  }
}

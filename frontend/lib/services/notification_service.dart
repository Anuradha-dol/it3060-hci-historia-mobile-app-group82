import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  final Dio _dio = ApiService.instance.dio;
  final StorageService _storageService = StorageService();

  final StreamController<AppNotification> _liveController =
      StreamController<AppNotification>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StompClient? _stompClient;
  int? _connectedUserId;

  Stream<AppNotification> get liveNotifications => _liveController.stream;

  Stream<bool> get connectionStatus => _connectionController.stream;

  Future<List<AppNotification>> getMine() async {
    final response = await _dio.get(ApiConfig.notifications);
    final List<dynamic> data = response.data;

    return data
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AppNotification> markRead(int id) async {
    final response = await _dio.patch(ApiConfig.markNotificationRead(id));

    return AppNotification.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> markAllRead() async {
    await _dio.patch(ApiConfig.markAllNotificationsRead);
  }

  Future<int> unreadCount() async {
    final response = await _dio.get(ApiConfig.notificationUnreadCount);
    final data = Map<String, dynamic>.from(response.data);

    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> connectLive(int userId) async {
    if (_connectedUserId == userId && _stompClient != null) {
      return;
    }

    disconnectLive();

    final token = await _storageService.getAccessToken();

    if (token == null || token.isEmpty) {
      _setConnected(false);
      return;
    }

    _connectedUserId = userId;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${ApiConfig.baseUrl}/ws',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: (_) {
          _setConnected(true);

          _stompClient?.subscribe(
            destination: '/topic/notifications/$userId',
            headers: {'Authorization': 'Bearer $token'},
            callback: (frame) {
              final body = frame.body;

              if (body == null || body.isEmpty) {
                return;
              }

              try {
                final decoded = jsonDecode(body);

                if (decoded is! Map) {
                  return;
                }

                _liveController.add(
                  AppNotification.fromJson(Map<String, dynamic>.from(decoded)),
                );
              } catch (_) {
                // Ignore malformed socket frames.
              }
            },
          );
        },
        onWebSocketError: (_) => _setConnected(false),
        onStompError: (_) => _setConnected(false),
        onDisconnect: (_) => _setConnected(false),
      ),
    );

    _stompClient?.activate();
  }

  void disconnectLive() {
    _stompClient?.deactivate();
    _stompClient = null;
    _connectedUserId = null;
    _setConnected(false);
  }

  void dispose() {
    disconnectLive();
    _liveController.close();
    _connectionController.close();
  }

  void _setConnected(bool connected) {
    if (!_connectionController.isClosed) {
      _connectionController.add(connected);
    }
  }
}

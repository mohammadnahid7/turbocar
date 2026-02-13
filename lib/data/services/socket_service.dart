/// Socket Service
/// Handles real-time communication via WebSocket (standard protocol)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/message_model.dart';

/// Connection state for the WebSocket
enum SocketConnectionState { disconnected, connecting, connected, reconnecting }

class SocketService {
  WebSocketChannel? _channel;
  SocketConnectionState _state = SocketConnectionState.disconnected;

  String? _serverUrl;
  String? _token;

  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  // Stream controllers
  final _messageController = StreamController<WSMessage>.broadcast();
  final _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();

  // Offline message queue
  final List<WSMessage> _offlineQueue = [];

  /// Stream of incoming messages
  Stream<WSMessage> get messageStream => _messageController.stream;

  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  SocketConnectionState get state => _state;

  /// Whether the socket is connected
  bool get isConnected => _state == SocketConnectionState.connected;

  /// Initialize and connect to WebSocket server
  Future<void> connect(String serverUrl, String token) async {
    _serverUrl = serverUrl;
    _token = token;

    await _connect();
  }

  Future<void> _connect() async {
    if (_state == SocketConnectionState.connecting) return;

    _updateState(SocketConnectionState.connecting);

    try {
      // Build WebSocket URL with JWT token as query parameter
      final wsUrl = Uri.parse('$_serverUrl?token=$_token');
      developer.log('WebSocket: Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);

      // Wait for connection to be established
      await _channel!.ready;

      _updateState(SocketConnectionState.connected);
      _reconnectAttempts = 0;
      developer.log('WebSocket: Connected successfully');

      // Send any queued messages
      _flushOfflineQueue();

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      developer.log('WebSocket: Connection error: $e');
      _updateState(SocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final message = WSMessage.fromJson(json);
      _messageController.add(message);
      developer.log(
        'WebSocket: Received ${message.type} for ${message.conversationId}',
      );
    } catch (e) {
      developer.log('WebSocket: Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    developer.log('WebSocket: Error: $error');
    _updateState(SocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    developer.log('WebSocket: Connection closed');
    _updateState(SocketConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _updateState(SocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _connectionStateController.add(newState);
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      developer.log('WebSocket: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, ... up to 30s
    final delay = Duration(
      milliseconds: min(
        _initialReconnectDelay.inMilliseconds *
            pow(2, _reconnectAttempts).toInt(),
        30000,
      ),
    );

    developer.log(
      'WebSocket: Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _updateState(SocketConnectionState.reconnecting);
      _connect();
    });
  }

  /// Send a message through WebSocket
  void send(WSMessage message) {
    if (isConnected && _channel != null) {
      final json = jsonEncode(message.toJson());
      _channel!.sink.add(json);
      developer.log('WebSocket: Sent ${message.type}');
    } else {
      // Queue message for when connection is restored
      _offlineQueue.add(message);
      developer.log('WebSocket: Queued message (offline)');
    }
  }

  /// Send all queued messages
  void _flushOfflineQueue() {
    if (_offlineQueue.isEmpty) return;

    developer.log(
      'WebSocket: Flushing ${_offlineQueue.length} queued messages',
    );
    for (final message in _offlineQueue) {
      send(message);
    }
    _offlineQueue.clear();
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateState(SocketConnectionState.disconnected);
    _reconnectAttempts = 0;
    developer.log('WebSocket: Disconnected');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

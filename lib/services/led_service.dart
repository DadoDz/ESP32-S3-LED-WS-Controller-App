import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/led_state.dart';

/// Talks to the LED controller over a plain WebSocket connection instead of
/// Firebase. The server on the other end (whatever sits between this app and
/// the ESP32) is expected to:
///   - push a full JSON state object `{power,red,green,blue,brightness}`
///     immediately when a client connects, and again whenever the state
///     changes (from any client, including the ESP32 itself)
///   - accept the same JSON shape sent up from this app and apply it
///
/// Note the ESP32 firmware expects every message to contain *all five*
/// fields (it doesn't merge partial updates), so this service always sends
/// the full known state rather than just the changed keys.
class LedService {
  LedService({
    required String uri, // e.g. ws://192.168.1.100:8080/ws or wss://your-server/ws
    this.debounceDuration = const Duration(milliseconds: 250),
  }) : _uri = Uri.parse(uri);

  final Uri _uri;
  final Duration debounceDuration;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  StreamController<LedState>? _controller;

  Timer? _debounceTimer;
  Map<String, dynamic>? _pendingWrite;

  LedState _currentState = const LedState();
  bool _connected = false;

  bool get isConnected => _connected;
  LedState get currentState => _currentState;

  /// Live stream of the LED state. Connects lazily on first listen and
  /// disconnects when the last listener cancels.
  Stream<LedState> watch() {
    _controller ??= StreamController<LedState>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  Future<void> _connect() async {
    await _disconnect();

    try {
      final channel = WebSocketChannel.connect(_uri);
      await channel.ready; // throws if the initial handshake fails
      _channel = channel;
      _connected = true;

      _channelSub = channel.stream.listen(
        _handleMessage,
        onError: (Object e) {
          _connected = false;
          _controller?.addError(e);
        },
        onDone: () {
          _connected = false;
          _controller?.addError(Exception('WebSocket connection closed'));
        },
        cancelOnError: false,
      );
    } catch (e) {
      // Deliberately NOT rethrown: this is called fire-and-forget from the
      // StreamController's onListen callback, and an unhandled exception
      // there crashes the app even though we already reported it below.
      _connected = false;
      _controller?.addError(e);
    }
  }

  Future<void> _disconnect() async {
    _connected = false;
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _currentState = LedState.fromMap(Map<String, dynamic>.from(decoded));
        _controller?.add(_currentState);
      }
    } catch (e) {
      _controller?.addError(Exception('Failed to parse WebSocket message: $e'));
    }
  }

  /// Ensures a connection exists (used for pull-to-refresh / retry). If
  /// already connected this is a no-op - state stays live via [watch].
  Future<void> ensureConnected() async {
    if (_connected) return;
    await _connect();
    if (!_connected) {
      throw StateError('Failed to connect to the WebSocket server');
    }
  }

  void _send(Map<String, dynamic> fullState) {
    if (_channel == null || !_connected) {
      throw StateError('Not connected to the WebSocket server');
    }
    _channel!.sink.add(jsonEncode(fullState));
  }

  /// Merges [values] into the last known state and sends the full object
  /// immediately, bypassing any pending debounce.
  Future<void> updateImmediate(Map<String, dynamic> values) async {
    _debounceTimer?.cancel();
    _pendingWrite = null;

    final merged = {..._currentState.toMap(), ...values};
    _currentState = LedState.fromMap(merged);
    _send(merged);
  }

  /// Same idea as [updateImmediate] but coalesces rapid calls (e.g. while
  /// dragging a slider) into a single send after [debounceDuration].
  void updateDebounced(Map<String, dynamic> values) {
    _pendingWrite = {...?_pendingWrite, ...values};
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      final toSend = _pendingWrite;
      _pendingWrite = null;
      if (toSend != null) {
        final merged = {..._currentState.toMap(), ...toSend};
        _currentState = LedState.fromMap(merged);
        try {
          _send(merged);
        } catch (_) {
          // Swallow - if we're disconnected the next state push will
          // resync the UI, no need to surface an error mid-drag.
        }
      }
    });
  }

  Future<void> flushPending() async {
    _debounceTimer?.cancel();
    final toSend = _pendingWrite;
    _pendingWrite = null;
    if (toSend != null) {
      final merged = {..._currentState.toMap(), ...toSend};
      _currentState = LedState.fromMap(merged);
      _send(merged);
    }
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _disconnect();
    await _controller?.close();
  }
}

/// App-wide configuration.
///
/// Point this at whatever server relays messages between this app and the
/// ESP32 (the same URI configured as WEBSOCKET_URI on the firmware side).
/// Use ws:// for a plain connection or wss:// if the server is behind TLS.
class AppConfig {
  static const String websocketUri = String.fromEnvironment(
    'WEBSOCKET_URI',
    defaultValue: 'ws://192.168.1.11:8080/ws',
  );
}

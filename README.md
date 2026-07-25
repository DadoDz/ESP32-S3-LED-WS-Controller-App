# ESP32-S3-LED-WS-Controller-App

A Flutter companion app for controlling an ESP32-S3 addressable/RGB LED setup in real time over a WebSocket connection - power, color, and brightness, synced instantly across every connected client.

## How it works

The app connects to a WebSocket server (whatever sits between the phone/desktop and the ESP32, could be the ESP32 itself or a small relay server) and exchanges a simple JSON state object:

```json
{
  "power": true,
  "red": 255,
  "green": 0,
  "blue": 0,
  "brightness": 100
}
```

- On connect, the server pushes the current state immediately.
- Any client (this app, another instance, or the ESP32 acting on a physical button) can push a new state, and every connected client updates live.
- The firmware is expected to consume the *full* state object on every message rather than partial updates, so the app always sends all five fields together.

## Features

- 🎨 Full RGB color control with live preview
- 💡 Brightness slider (0–100)
- 🔌 Power toggle
- 🎲 Random color generator
- ⚡ Debounced updates while dragging sliders, with immediate flush on release, to avoid flooding the connection
- 🔄 Automatic reconnect / pull-to-refresh support
- 🖥️ Builds for Android and Windows

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- An ESP32-S3 (or similar) running firmware that speaks the JSON schema above over WebSocket
- A [WebSocket](https://github.com/DadoDz/iot-websocket-relay) endpoint reachable from your device (e.g. `ws://192.168.x.xx:8080/ws`)

### Setup

```bash
git clone https://github.com/DadoDz/ESP32-S3-LED-WS-Controller-App.git
cd ESP32-S3-LED-WS-Controller-App
flutter pub get
```

### Running

By default the app points at `ws://192.168.x.xx:8080/ws`. Override it at build/run time with `--dart-define`:

```bash
flutter run --dart-define=WEBSOCKET_URI=ws://192.168.x.xx:8080/ws
```

Use `wss://` instead of `ws://` if your server is behind TLS.

## Project structure

```
lib/
├── config/          # App-wide config (WebSocket URI)
├── models/          # LedState — the shared JSON schema
├── services/        # LedService — WebSocket connection, debouncing, reconnect logic
├── screens/         # Dashboard screen
├── theme/           # App theming
└── widgets/         # RGB slider, brightness slider, power toggle, color preview, etc.
```

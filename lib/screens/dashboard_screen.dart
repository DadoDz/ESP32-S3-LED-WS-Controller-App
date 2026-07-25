import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/led_state.dart';
import '../services/led_service.dart';
import '../theme/app_theme.dart';
import '../widgets/color_preview.dart';
import '../widgets/glass_card.dart';
import '../widgets/power_toggle.dart';
import '../widgets/rgb_slider.dart';
import '../widgets/brightness_slider.dart';

/// Layout switches to a two-column view above this width (desktop window,
/// tablet landscape); below it, everything stacks in a single scrollable
/// column (phone).
const double _wideBreakpoint = 780;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LedService _service = LedService(uri: AppConfig.websocketUri);
  final Random _random = Random();

  LedState _state = const LedState();
  StreamSubscription<LedState>? _subscription;
  bool _loading = true;
  String? _error;
  bool _offline = false;
  bool _receivedFirstState = false;

  bool _suppressRemoteWhileDragging = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
      _receivedFirstState = false;
    });

    _subscription?.cancel();
    _subscription = _service.watch().listen(
      (remoteState) {
        if (!mounted) return;
        setState(() {
          if (!_suppressRemoteWhileDragging) {
            _state = remoteState;
          }
          if (!_receivedFirstState) {
            _receivedFirstState = true;
            _loading = false;
          }
        });
      },
      onError: (e) {
        debugPrint('[LED] WebSocket error: $e');
        if (mounted && !_receivedFirstState) {
          final isConnectionIssue = e is StateError ||
              e.toString().toLowerCase().contains('socket') ||
              e.toString().toLowerCase().contains('connect');
          setState(() {
            _loading = false;
            if (isConnectionIssue) {
              _offline = true;
            } else {
              _error = e.toString();
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await _service.ensureConnected();
      setState(() => _offline = false);
    } catch (_) {
      setState(() => _offline = true);
    }
  }

  void _setPower(bool value) {
    setState(() => _state = _state.copyWith(power: value));
    _service.updateImmediate({'power': value});
  }

  void _onRandomColor() {
    final newState = _state.copyWith(
      red: _random.nextInt(256),
      green: _random.nextInt(256),
      blue: _random.nextInt(256),
    );
    setState(() => _state = newState);
    _service.updateImmediate({
      'red': newState.red,
      'green': newState.green,
      'blue': newState.blue,
    });
  }

  void _onChannelDrag(String key, int value) {
    _suppressRemoteWhileDragging = true;
    setState(() {
      _state = switch (key) {
        'red' => _state.copyWith(red: value),
        'green' => _state.copyWith(green: value),
        'blue' => _state.copyWith(blue: value),
        _ => _state,
      };
    });
    _service.updateDebounced({key: value});
  }

  void _onChannelDragEnd(int _) {
    _suppressRemoteWhileDragging = false;
    _service.flushPending();
  }

  void _onBrightnessDrag(int value) {
    _suppressRemoteWhileDragging = true;
    setState(() => _state = _state.copyWith(brightness: value));
    _service.updateDebounced({'brightness': value});
  }

  void _onBrightnessDragEnd(int _) {
    _suppressRemoteWhileDragging = false;
    _service.flushPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _offline
                ? _buildOfflineState()
                : _error != null
                    ? _buildErrorState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= _wideBreakpoint;
                          return RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _handleRefresh,
                            child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                          );
                        },
                      ),
      ),
    );
  }

  // ---- Phone layout: single scrollable column ----
  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        PowerToggle(power: _state.power, onChanged: _setPower),
        const SizedBox(height: 16),
        ColorPreview(state: _state, onRandomize: _onRandomColor),
        const SizedBox(height: 20),
        _buildRgbSection(),
        const SizedBox(height: 16),
        _buildBrightnessSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---- Desktop/tablet layout: fixed-width left panel, wider right panel ----
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: Column(
                        children: [
                          PowerToggle(power: _state.power, onChanged: _setPower),
                          const SizedBox(height: 16),
                          ColorPreview(state: _state, onRandomize: _onRandomColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildRgbSection(),
                          const SizedBox(height: 16),
                          _buildBrightnessSection(),
                        ],
                      ),
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

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No connection',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check that the relay server and your Wi-Fi are both reachable.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Couldn't reach the LED controller",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.developer_board_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESP32-S3 LED',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'Live WebSocket control',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        _buildLiveBadge(),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRgbSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color channels',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          RgbSlider(
            channel: 'R',
            value: _state.red,
            trackColor: AppColors.channelRed,
            onChanged: (v) => _onChannelDrag('red', v),
            onChangeEnd: _onChannelDragEnd,
          ),
          RgbSlider(
            channel: 'G',
            value: _state.green,
            trackColor: AppColors.channelGreen,
            onChanged: (v) => _onChannelDrag('green', v),
            onChangeEnd: _onChannelDragEnd,
          ),
          RgbSlider(
            channel: 'B',
            value: _state.blue,
            trackColor: AppColors.channelBlue,
            onChanged: (v) => _onChannelDrag('blue', v),
            onChangeEnd: _onChannelDragEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brightness',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          BrightnessSlider(
            value: _state.brightness,
            onChanged: _onBrightnessDrag,
            onChangeEnd: _onBrightnessDragEnd,
          ),
        ],
      ),
    );
  }
}

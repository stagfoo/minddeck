import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// The thin bar across the top: clock on the left, actions on the right — the
/// Switch's user/time/battery strip, minus the things a phone already draws in
/// its own status bar.
class StatusStrip extends StatefulWidget {
  const StatusStrip({
    super.key,
    required this.onSettings,
    required this.onSearch,
    this.onLongPressClock,
  });

  final VoidCallback onSettings;
  final VoidCallback onSearch;

  /// Long-pressing the clock reports the measured panel geometry. There is no
  /// adb on this device day to day, and the whole layout is tuned to numbers
  /// that had to be guessed until it ran — this is how they get confirmed.
  final VoidCallback? onLongPressClock;

  @override
  State<StatusStrip> createState() => _StatusStripState();
}

class _StatusStripState extends State<StatusStrip> {
  late Timer _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Ticking per second would rebuild sixty times more often than the display
    // can change; align to the minute instead.
    _tick = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeckMetrics.stripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DeckMetrics.deckPadding),
        child: Row(
          children: [
            GestureDetector(
              onLongPress: widget.onLongPressClock,
              child: Text(
                formatClock(_now),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: DeckColors.text,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            _StripButton(icon: Icons.search, onTap: widget.onSearch),
            const SizedBox(width: 4),
            _StripButton(icon: Icons.settings_outlined, onTap: widget.onSettings),
          ],
        ),
      ),
    );
  }
}

/// 24-hour, zero-padded — "09:05".
String formatClock(DateTime when) {
  final hour = when.hour.toString().padLeft(2, '0');
  final minute = when.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _StripButton extends StatelessWidget {
  const _StripButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: DeckColors.textDim),
      ),
    );
  }
}

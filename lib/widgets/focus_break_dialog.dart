import 'dart:async';
import 'package:flutter/material.dart';

/// Research basis: Slattery (2022) + Eberhart (2025) meta-analysis.
/// 8–12 min focused work → 2–3 min physical/mental break →
/// improved sustained attention and working memory encoding.
class FocusBreakDialog extends StatefulWidget {
  final Duration breakDuration;
  const FocusBreakDialog({
    super.key,
    this.breakDuration = const Duration(minutes: 2),
  });

  @override
  State<FocusBreakDialog> createState() => _FocusBreakDialogState();
}

class _FocusBreakDialogState extends State<FocusBreakDialog> {
  late Timer _timer;
  late int _remaining;
  int _activityIndex = 0;

  // Movement/mental break activities — evidence-based (embodied cognition research)
  static const _activities = [
    _BreakActivity(
      icon: '🚶',
      title: 'Walk Around',
      instruction: 'Stand up and walk around the room for 2 minutes.\n'
          'No screens. Let your mind wander freely.',
      type: 'physical',
    ),
    _BreakActivity(
      icon: '💧',
      title: 'Hydrate & Stretch',
      instruction: 'Drink some water.\n'
          'Roll your shoulders back 5 times. Tilt your head left, then right.',
      type: 'physical',
    ),
    _BreakActivity(
      icon: '🌬️',
      title: 'Box Breathing',
      instruction: 'Inhale for 4 counts → Hold for 4 → Exhale for 4 → Hold for 4.\n'
          'Repeat 3 times. This resets your focus.',
      type: 'breathing',
    ),
    _BreakActivity(
      icon: '👀',
      title: '20-20-20 Eye Break',
      instruction: 'Look at something 20 feet away for 20 seconds.\n'
          'Blink 20 times slowly. Reduces eye strain from screen work.',
      type: 'physical',
    ),
    _BreakActivity(
      icon: '🧠',
      title: 'Quick Recall',
      instruction: 'Without looking at your notes, write down 3 things\n'
          'you remember from the last session. Then check.',
      type: 'cognitive',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _remaining = widget.breakDuration.inSeconds;
    _activityIndex = DateTime.now().second % _activities.length;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer.cancel();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activities[_activityIndex];
    final progress = 1.0 -
        (_remaining / widget.breakDuration.inSeconds).clamp(0.0, 1.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(28),
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(activity.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            '⏸ Focus Break',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Research-based break to restore attention capacity.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Timer ring
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade800,
                color: Colors.green,
              ),
            ),
            Text(
              '${_remaining}s',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 20),
          Text(activity.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            activity.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          // Activity switcher
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton.icon(
              onPressed: () => setState(() =>
                  _activityIndex =
                      (_activityIndex + 1) % _activities.length),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Different activity'),
            ),
          ]),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _timer.cancel();
              Navigator.of(context).pop(true);
            },
            child: const Text('Skip break (not recommended)'),
          ),
        ]),
      ),
    );
  }
}

class _BreakActivity {
  final String icon, title, instruction, type;
  const _BreakActivity({
    required this.icon, required this.title,
    required this.instruction, required this.type,
  });
}

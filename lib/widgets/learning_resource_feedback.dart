import 'package:flutter/material.dart';

import '../core/models/learning_resource.dart';

/// Wraps any pedagogical renderer (video, story panel, game, simulation, text,
/// etc.) with a consistent learner-controlled feedback surface.
///
/// The widget emits explicit pedagogical signals only. It does not persist
/// feedback, infer mastery, or collect watch-time/engagement telemetry.
class LearningResourceMoment extends StatelessWidget {
  final LearningResource resource;
  final Widget child;
  final ValueChanged<LearningFeedbackSignal> onFeedback;
  final bool showFineGrainedFeedback;

  const LearningResourceMoment({
    super.key,
    required this.resource,
    required this.child,
    required this.onFeedback,
    this.showFineGrainedFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Learning resource: ${resource.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          child,
          const SizedBox(height: 16),
          LearningResourceFeedbackPanel(
            onFeedback: onFeedback,
            showFineGrainedFeedback: showFineGrainedFeedback,
          ),
        ],
      ),
    );
  }
}

class LearningResourceFeedbackPanel extends StatelessWidget {
  final ValueChanged<LearningFeedbackSignal> onFeedback;
  final bool showFineGrainedFeedback;

  const LearningResourceFeedbackPanel({
    super.key,
    required this.onFeedback,
    this.showFineGrainedFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Tell Axiom how this explanation worked for you',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Did this help?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your answer helps choose the next explanation. It does not change what you are required to learn.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FeedbackButton(
                label: 'That helped',
                icon: Icons.thumb_up_outlined,
                onPressed: () => onFeedback(LearningFeedbackSignal.helpful),
              ),
              _FeedbackButton(
                label: 'I still don’t get it',
                icon: Icons.help_outline,
                onPressed: () =>
                    onFeedback(LearningFeedbackSignal.stillConfused),
              ),
              _FeedbackButton(
                label: 'Show me another way',
                icon: Icons.swap_horiz,
                onPressed: () =>
                    onFeedback(LearningFeedbackSignal.showAnotherWay),
              ),
              _FeedbackButton(
                label: 'More like this',
                icon: Icons.auto_awesome_outlined,
                onPressed: () =>
                    onFeedback(LearningFeedbackSignal.moreLikeThis),
              ),
            ],
          ),
          if (showFineGrainedFeedback) ...<Widget>[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text('Tell me more'),
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _FeedbackButton(
                        label: 'Too fast',
                        icon: Icons.fast_forward_outlined,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.tooFast),
                      ),
                      _FeedbackButton(
                        label: 'Too slow',
                        icon: Icons.slow_motion_video_outlined,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.tooSlow),
                      ),
                      _FeedbackButton(
                        label: 'Too easy',
                        icon: Icons.trending_flat,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.tooEasy),
                      ),
                      _FeedbackButton(
                        label: 'Too hard',
                        icon: Icons.trending_up,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.tooHard),
                      ),
                      _FeedbackButton(
                        label: 'I liked this example',
                        icon: Icons.lightbulb_outline,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.likedExample),
                      ),
                      _FeedbackButton(
                        label: 'I already knew this',
                        icon: Icons.check_circle_outline,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.alreadyKnewThis),
                      ),
                      _FeedbackButton(
                        label: 'Not helpful',
                        icon: Icons.thumb_down_outlined,
                        onPressed: () =>
                            onFeedback(LearningFeedbackSignal.notHelpful),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

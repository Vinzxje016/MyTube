import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GenreLabels extends StatelessWidget {
  final List<String> labels;
  final int maxLabels;

  const GenreLabels({super.key, required this.labels, this.maxLabels = 3});

  @override
  Widget build(BuildContext context) {
    final visible = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final shown = visible.take(maxLabels).toList();
    final hiddenCount = visible.length - shown.length;
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final label in shown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.primary.withAlpha(90)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.accentColor,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ),
        if (hiddenCount > 0)
          Text(
            '+$hiddenCount',
            style: TextStyle(color: context.mutedTextColor, fontSize: 10),
          ),
      ],
    );
  }
}

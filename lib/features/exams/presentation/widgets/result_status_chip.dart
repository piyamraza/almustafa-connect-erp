import 'package:flutter/material.dart';

import '../../domain/entities/exam_result_entity.dart';

class ResultStatusChip extends StatelessWidget {
  const ResultStatusChip({required this.status, super.key});

  final ResultStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      ResultStatus.draft => ('Draft', colors.secondary),
      ResultStatus.generated => ('Generated', const Color(0xFF0288D1)),
      ResultStatus.verified => ('Verified', const Color(0xFF00897B)),
      ResultStatus.approved => ('Approved', const Color(0xFF7B1FA2)),
      ResultStatus.published => ('Published', colors.primary),
      ResultStatus.locked => ('Locked', colors.error),
      ResultStatus.unpublished => ('Unpublished', colors.tertiary),
    };
    return Chip(
      avatar: Icon(
        status == ResultStatus.locked ? Icons.lock_outline : Icons.circle,
        size: 14,
        color: color,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

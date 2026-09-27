import 'package:flutter/material.dart';
import '../models/pipeline_stage.dart';

class StatusBadge extends StatelessWidget {
  final PipelineStage stage;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.stage,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: stage.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stage.color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stage.icon, size: 12, color: stage.color),
            const SizedBox(width: 4),
            Text(
              stage.displayName,
              style: TextStyle(
                color: stage.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: stage.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stage.color.withOpacity(0.5), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage.icon, size: 16, color: stage.color),
          const SizedBox(width: 6),
          Text(
            stage.displayName,
            style: TextStyle(
              color: stage.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

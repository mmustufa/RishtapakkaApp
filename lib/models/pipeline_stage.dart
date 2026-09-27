import 'package:flutter/material.dart';

/// Pipeline tracking states for candidate profiles and match proposals
enum PipelineStage {
  pendingReview(
    key: 'pending_review',
    displayName: 'Pending Review',
    description: 'Fresh profile scanned/submitted. Awaiting agent verification.',
    color: Color(0xFFE5A100), // Amber / Warm Gold
    icon: Icons.hourglass_top_rounded,
  ),
  proposalSent(
    key: 'proposal_sent',
    displayName: 'In Progress / Proposal Sent',
    description: 'Biodata/photo dispatched to opposite family.',
    color: Color(0xFF2563EB), // Royal Blue
    icon: Icons.send_rounded,
  ),
  familyDiscussion(
    key: 'family_discussion',
    displayName: 'Family Discussion',
    description: 'Both families actively reviewing terms, photos, or meeting.',
    color: Color(0xFF7C3AED), // Royal Purple
    icon: Icons.groups_rounded,
  ),
  shortlisted(
    key: 'shortlisted',
    displayName: 'Accepted / Shortlisted',
    description: 'Both parties agreed to proceed towards engagement/Nikah.',
    color: Color(0xFF059669), // Emerald Green
    icon: Icons.check_circle_rounded,
  ),
  closed(
    key: 'closed',
    displayName: 'Declined / Closed',
    description: 'Match rejected by either party or profile withdrawn.',
    color: Color(0xFFDC2626), // Crimson Red
    icon: Icons.cancel_rounded,
  );

  final String key;
  final String displayName;
  final String description;
  final Color color;
  final IconData icon;

  const PipelineStage({
    required this.key,
    required this.displayName,
    required this.description,
    required this.color,
    required this.icon,
  });

  static PipelineStage fromKey(String? key) {
    if (key == null) return PipelineStage.pendingReview;
    return PipelineStage.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PipelineStage.pendingReview,
    );
  }
}

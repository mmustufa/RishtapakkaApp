import 'dart:io';
import 'package:flutter/material.dart';
import '../models/candidate.dart';
import 'status_badge.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onTap;
  final VoidCallback onFindMatches;
  final VoidCallback onShare;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onTap,
    required this.onFindMatches,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = candidate.isMale;
    final hasPhoto = candidate.photoPath != null &&
        File(candidate.photoPath!).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMale
              ? Colors.blue.withOpacity(0.25)
              : Colors.pink.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar + Info + Status ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo or gender avatar
                  Container(
                    width: 58,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(12),
                      image: hasPhoto
                          ? DecorationImage(
                              image: FileImage(File(candidate.photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasPhoto
                        ? Icon(
                            isMale ? Icons.man_rounded : Icons.woman_rounded,
                            size: 36,
                            color: isMale ? Colors.blue.shade700 : Colors.pink.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name, subtitle, DOB
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${candidate.name} (${candidate.gender})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${candidate.age} yrs • ${candidate.heightDisplay} • ${candidate.city}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (candidate.dob.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.cake_rounded, size: 11, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                'DOB: ${candidate.dob}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                        if (candidate.occupation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              candidate.occupation,
                              style: TextStyle(fontSize: 10, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(stage: candidate.pipelineStatus, isCompact: true),
                ],
              ),
              const SizedBox(height: 10),

              // ── Tags: Sect, Caste, Education ──
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _infoChip(
                    icon: Icons.mosque_rounded,
                    label: candidate.sect,
                    bgColor: const Color(0xFFD1FAE5),
                    textColor: const Color(0xFF065F46),
                  ),
                  _infoChip(
                    icon: Icons.people_outline_rounded,
                    label: candidate.caste,
                    bgColor: Colors.purple.shade50,
                    textColor: Colors.purple.shade900,
                  ),
                  _infoChip(
                    icon: Icons.school_rounded,
                    label: '${candidate.education} (T${candidate.educationTier.rank})',
                    bgColor: Colors.amber.shade50,
                    textColor: Colors.amber.shade900,
                  ),
                ],
              ),

              const Divider(height: 16, thickness: 0.8),

              // ── Footer: Ref + Share + Match ──
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ref: ${candidate.agentReferenceName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Share Button
                  OutlinedButton.icon(
                    onPressed: onShare,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                      foregroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: const Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  // Match Button
                  ElevatedButton.icon(
                    onPressed: onFindMatches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMale ? const Color(0xFF1E3A8A) : const Color(0xFF9D174D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 14),
                    label: const Text('Match', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(7)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

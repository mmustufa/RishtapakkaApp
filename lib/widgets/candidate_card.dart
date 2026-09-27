import 'dart:io';
import 'package:flutter/material.dart';
import '../models/candidate.dart';
import 'status_badge.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onTap;
  final VoidCallback onFindMatches;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onTap,
    required this.onFindMatches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = candidate.isMale;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMale
              ? Colors.blue.withOpacity(0.2)
              : Colors.pink.withOpacity(0.2),
          width: 1.2,
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
              // Header Row: Avatar, Name & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo or Gender-colored avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isMale
                          ? Colors.blue.shade50
                          : Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(12),
                      image: candidate.photoPath != null &&
                              File(candidate.photoPath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(candidate.photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: candidate.photoPath == null ||
                            !File(candidate.photoPath!).existsSync()
                        ? Icon(
                            isMale ? Icons.man_rounded : Icons.woman_rounded,
                            size: 34,
                            color: isMale
                                ? Colors.blue.shade700
                                : Colors.pink.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name, Age, Height
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${candidate.age} yrs • ${candidate.heightDisplay} • ${candidate.city}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(stage: candidate.pipelineStatus, isCompact: true),
                ],
              ),
              const SizedBox(height: 12),

              // Chips for Sect, Caste & Education Tier
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
                    label: candidate.education,
                    bgColor: Colors.amber.shade50,
                    textColor: Colors.amber.shade900,
                  ),
                ],
              ),

              const Divider(height: 20, thickness: 0.8),

              // Footer: Submitting Agent Name & Find Matches Button
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ref: ${candidate.agentReferenceName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onFindMatches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMale
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF9D174D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 16),
                    label: const Text(
                      'Find Matches',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Colors {
  static Color emeraldColor() => const Color(0xFFD1FAE5);
}

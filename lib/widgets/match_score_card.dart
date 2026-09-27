import 'package:flutter/material.dart';
import '../matching/matching_engine.dart';
import '../models/candidate.dart';

class MatchScoreCard extends StatelessWidget {
  final Candidate targetCandidate;
  final MatchEvaluationResult matchResult;
  final VoidCallback onInitiateProposal;
  final VoidCallback onViewProfile;

  const MatchScoreCard({
    super.key,
    required this.targetCandidate,
    required this.matchResult,
    required this.onInitiateProposal,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = matchResult.candidate;
    final validation = matchResult.validation;
    final isFullMatch = validation.isFullMatch;
    final isGroom = candidate.isMale;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFullMatch ? Colors.green.shade400 : Colors.red.shade300,
          width: 1.4,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Candidate name, age, city & Compatibility Score badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGroom ? Icons.man : Icons.woman,
                            color: isGroom ? Colors.blue : Colors.pink,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              candidate.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${candidate.age} yrs • ${candidate.heightDisplay} • ${candidate.city}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score circle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isFullMatch
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFullMatch
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isFullMatch
                            ? '${matchResult.compatibilityScore.toStringAsFixed(0)}%'
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isFullMatch
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                      Text(
                        isFullMatch ? 'MATCH' : 'INELIGIBLE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isFullMatch
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Strict Rules Breakdown
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _ruleRow(
                    label: 'Sect (Maslak)',
                    value: candidate.sect,
                    isPassed: validation.isSectMatch,
                  ),
                  const SizedBox(height: 6),
                  _ruleRow(
                    label: 'Caste (Biradari)',
                    value: candidate.caste,
                    isPassed: validation.isCasteMatch,
                  ),
                  const SizedBox(height: 6),
                  _ruleRow(
                    label: 'Height Rule (Groom > Bride)',
                    value:
                        'Groom: ${targetCandidate.isMale ? targetCandidate.heightDisplay : candidate.heightDisplay} | Bride: ${targetCandidate.isFemale ? targetCandidate.heightDisplay : candidate.heightDisplay}',
                    isPassed: validation.isHeightValid,
                  ),
                  const SizedBox(height: 6),
                  _ruleRow(
                    label: 'Education Hierarchy (Groom >= Bride)',
                    value:
                        'Groom: ${targetCandidate.isMale ? targetCandidate.educationTier.name : candidate.educationTier.name} | Bride: ${targetCandidate.isFemale ? targetCandidate.educationTier.name : candidate.educationTier.name}',
                    isPassed: validation.isEducationValid,
                  ),
                ],
              ),
            ),

            if (!isFullMatch) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        validation.rejectionReasons.join('\n'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Submitting Agent & Action Buttons
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Agent: ${candidate.agentReferenceName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onViewProfile,
                  child: const Text('View Full Bio'),
                ),
                const SizedBox(width: 8),
                if (isFullMatch)
                  ElevatedButton.icon(
                    onPressed: onInitiateProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Proposal'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow({
    required String label,
    required String value,
    required bool isPassed,
  }) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: isPassed ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

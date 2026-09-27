import '../models/candidate.dart';

class MatchRuleValidation {
  final bool isGenderComplementary;
  final bool isSectMatch;
  final bool isCasteMatch;
  final bool isHeightValid; // Male height strictly > Female height
  final bool isEducationValid; // Male education tier >= Female education tier
  final List<String> rejectionReasons;

  MatchRuleValidation({
    required this.isGenderComplementary,
    required this.isSectMatch,
    required this.isCasteMatch,
    required this.isHeightValid,
    required this.isEducationValid,
    required this.rejectionReasons,
  });

  /// All 4 strict criteria must be fulfilled
  bool get isFullMatch =>
      isGenderComplementary &&
      isSectMatch &&
      isCasteMatch &&
      isHeightValid &&
      isEducationValid;
}

class MatchEvaluationResult {
  final Candidate candidate;
  final MatchRuleValidation validation;
  final double compatibilityScore; // 0.0 to 100.0%
  final String compatibilitySummary;

  MatchEvaluationResult({
    required this.candidate,
    required this.validation,
    required this.compatibilityScore,
    required this.compatibilitySummary,
  });
}

class MatchingEngine {
  /// Validates the 4 strict criteria between two candidates
  static MatchRuleValidation validateRules({
    required Candidate target,
    required Candidate potential,
  }) {
    final reasons = <String>[];

    // 1. Gender Complementarity
    final bool isGenderComplementary =
        target.isMale ? potential.isFemale : potential.isMale;
    if (!isGenderComplementary) {
      reasons.add('Gender Conflict: Both are ${target.gender}');
    }

    // 2. Sect (Maslak) Compatibility - Strict Exact Match
    final bool isSectMatch =
        target.sect.trim().toLowerCase() == potential.sect.trim().toLowerCase();
    if (!isSectMatch) {
      reasons.add('Sect Mismatch: "${target.sect}" vs "${potential.sect}"');
    }

    // 3. Caste (Biradari) Compatibility - Strict Exact Match
    final bool isCasteMatch =
        target.caste.trim().toLowerCase() == potential.caste.trim().toLowerCase();
    if (!isCasteMatch) {
      reasons.add('Caste Mismatch: "${target.caste}" vs "${potential.caste}"');
    }

    // Identify who is Male and who is Female
    final Candidate? male = target.isMale
        ? target
        : (potential.isMale ? potential : null);
    final Candidate? female = target.isFemale
        ? target
        : (potential.isFemale ? potential : null);

    bool isHeightValid = false;
    bool isEducationValid = false;

    if (male != null && female != null) {
      // 4. Height Constraint: Male must be strictly taller than Female
      isHeightValid = male.heightInches > female.heightInches;
      if (!isHeightValid) {
        reasons.add(
          'Height Constraint Failed: Groom (${male.heightDisplay}) must be strictly taller than Bride (${female.heightDisplay})',
        );
      }

      // 5. Educational Hierarchy: Male tier >= Female tier
      isEducationValid = male.educationTier.rank >= female.educationTier.rank;
      if (!isEducationValid) {
        reasons.add(
          'Education Hierarchy Failed: Groom (${male.educationTier.label}) must be equal to or higher than Bride (${female.educationTier.label})',
        );
      }
    } else {
      reasons.add('Cannot evaluate height/education hierarchy for same-gender pair.');
    }

    return MatchRuleValidation(
      isGenderComplementary: isGenderComplementary,
      isSectMatch: isSectMatch,
      isCasteMatch: isCasteMatch,
      isHeightValid: isHeightValid,
      isEducationValid: isEducationValid,
      rejectionReasons: reasons,
    );
  }

  /// Calculates a 0-100 compatibility score for qualified matches
  static double calculateCompatibilityScore({
    required Candidate target,
    required Candidate potential,
  }) {
    double score = 50.0; // Base score for clearing all 4 strict criteria

    // 1. Age Difference Score (Max +25)
    // Desired: Male is 1-5 years older than Female
    final maleAge = target.isMale ? target.age : potential.age;
    final femaleAge = target.isFemale ? target.age : potential.age;
    final ageDiff = maleAge - femaleAge;

    if (ageDiff >= 1 && ageDiff <= 4) {
      score += 25.0; // Ideal cultural age gap
    } else if (ageDiff == 0 || (ageDiff >= 5 && ageDiff <= 7)) {
      score += 18.0;
    } else if (ageDiff > 7 && ageDiff <= 10) {
      score += 10.0;
    } else if (ageDiff < 0) {
      score += 2.0; // Groom younger than bride
    }

    // 2. City / Geographical Convenience Score (Max +15)
    if (target.city.trim().toLowerCase() == potential.city.trim().toLowerCase()) {
      score += 15.0; // Same city
    } else {
      score += 5.0;
    }

    // 3. Education Proximity (Max +10)
    final maleTier = target.isMale ? target.educationTier.rank : potential.educationTier.rank;
    final femaleTier = target.isFemale ? target.educationTier.rank : potential.educationTier.rank;
    final tierDiff = maleTier - femaleTier;

    if (tierDiff == 0 || tierDiff == 1) {
      score += 10.0; // Closely matched intellectual tier
    } else if (tierDiff == 2) {
      score += 6.0;
    } else {
      score += 2.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Finds and ranks all eligible matches from a candidate pool
  static List<MatchEvaluationResult> findMatches({
    required Candidate target,
    required List<Candidate> candidatePool,
    bool strictOnly = true,
  }) {
    final results = <MatchEvaluationResult>[];

    for (final potential in candidatePool) {
      // Cannot match with oneself
      if (potential.id == target.id) continue;

      final validation = validateRules(
        target: target,
        potential: potential,
      );

      if (strictOnly && !validation.isFullMatch) {
        continue;
      }

      final score = validation.isFullMatch
          ? calculateCompatibilityScore(target: target, potential: potential)
          : 0.0;

      final summary = validation.isFullMatch
          ? '100% Strict Criteria Cleared (Score: ${score.toStringAsFixed(0)}%)'
          : 'Failed: ${validation.rejectionReasons.join(' | ')}';

      results.add(
        MatchEvaluationResult(
          candidate: potential,
          validation: validation,
          compatibilityScore: score,
          compatibilitySummary: summary,
        ),
      );
    }

    // Sort by compatibility score descending
    results.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    return results;
  }
}

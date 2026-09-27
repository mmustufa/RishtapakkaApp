/// Hierarchical Education Tiers for Muslim Marriage Bureau Matching.
/// Rule: Male candidate's education tier must be >= Female candidate's tier.
enum EducationTier {
  unspecified(0, 'Unspecified / Below Matric'),
  matric(1, 'Matric / O-Levels / 10th Standard'),
  intermediate(2, 'Intermediate / A-Levels / 12th / FSc / ICS / FA'),
  diploma(3, 'Associate Degree / 3-Year Diploma / DAE'),
  bachelors(4, 'Bachelors / Graduate (BS, B.Tech, B.Com, BA, BSc, BBA, LLB, BE, BDS)'),
  masters(5, 'Masters / Post-Graduate (MS, M.Tech, MBA, M.Com, MA, MSc, MBBS, MD, CA, ACCA)'),
  doctorate(6, 'Doctorate / PhD / Post-Doc');

  final int rank;
  final String label;

  const EducationTier(this.rank, this.label);

  /// Check if this tier is equal to or higher than [other].
  bool isGreaterOrEqual(EducationTier other) {
    return rank >= other.rank;
  }

  /// Maps freeform text from OCR into a normalized [EducationTier].
  static EducationTier fromString(String rawText) {
    final text = rawText.toUpperCase();

    // Doctorate / PhD
    if (text.contains('PHD') ||
        text.contains('DOCTORATE') ||
        text.contains('POST DOC') ||
        text.contains('PHIL')) {
      return EducationTier.doctorate;
    }

    // Masters & Professional Postgrad
    if (text.contains('MASTERS') ||
        text.contains('POST GRAD') ||
        text.contains('MS ') ||
        text.contains('M.S') ||
        text.contains('MBA') ||
        text.contains('MTECH') ||
        text.contains('M.TECH') ||
        text.contains('MBBS') ||
        text.contains('M.D') ||
        text.contains('MD ') ||
        text.contains('FCPS') ||
        text.contains('M.COM') ||
        text.contains('MCOM') ||
        text.contains('M.A') ||
        text.contains('MSC') ||
        text.contains('M.SC') ||
        text.contains('MCA') ||
        text.contains('CA ') ||
        text.contains('ACCA')) {
      return EducationTier.masters;
    }

    // Bachelors
    if (text.contains('BACHELOR') ||
        text.contains('GRADUATE') ||
        text.contains('BS ') ||
        text.contains('B.S') ||
        text.contains('B.TECH') ||
        text.contains('BTECH') ||
        text.contains('B.E') ||
        text.contains('BE ') ||
        text.contains('BBA') ||
        text.contains('B.B.A') ||
        text.contains('B.COM') ||
        text.contains('BCOM') ||
        text.contains('B.SC') ||
        text.contains('BSC') ||
        text.contains('B.A') ||
        text.contains('BA ') ||
        text.contains('LLB') ||
        text.contains('L.L.B') ||
        text.contains('BDS') ||
        text.contains('B.PHARM') ||
        text.contains('BPHARM') ||
        text.contains('DEGREE')) {
      return EducationTier.bachelors;
    }

    // Associate / Diploma
    if (text.contains('DIPLOMA') ||
        text.contains('ASSOCIATE') ||
        text.contains('DAE') ||
        text.contains('POLYTECHNIC')) {
      return EducationTier.diploma;
    }

    // Intermediate
    if (text.contains('INTER') ||
        text.contains('INTERMEDIATE') ||
        text.contains('12TH') ||
        text.contains('12 TH') ||
        text.contains('HSSC') ||
        text.contains('FSC') ||
        text.contains('F.SC') ||
        text.contains('ICS') ||
        text.contains('I.C.S') ||
        text.contains('FA') ||
        text.contains('F.A') ||
        text.contains('A LEVEL') ||
        text.contains('A-LEVEL') ||
        text.contains('SENIOR SECONDARY')) {
      return EducationTier.intermediate;
    }

    // Matric
    if (text.contains('MATRIC') ||
        text.contains('10TH') ||
        text.contains('10 TH') ||
        text.contains('SSC') ||
        text.contains('O LEVEL') ||
        text.contains('O-LEVEL') ||
        text.contains('SECONDARY SCHOOL') ||
        text.contains('HIGH SCHOOL')) {
      return EducationTier.matric;
    }

    return EducationTier.unspecified;
  }
}

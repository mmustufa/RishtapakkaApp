import '../models/candidate.dart';
import '../models/education_tier.dart';
import '../models/pipeline_stage.dart';

class ParsedBiodataResult {
  final String rawText;
  final String name;
  final String gender;
  final String dob;
  final int age;
  final double heightInches;
  final String heightDisplay;
  final double weightKg;
  final String complexion;
  final String education;
  final EducationTier educationTier;
  final String occupation;
  final String sect;
  final String caste;
  final String city;
  final String address;
  final String contactNumber;
  final String fatherName;
  final String fatherOccupation;
  final String motherName;
  final String agentReferenceName;
  final String notes;

  ParsedBiodataResult({
    required this.rawText,
    required this.name,
    required this.gender,
    this.dob = '',
    required this.age,
    required this.heightInches,
    required this.heightDisplay,
    this.weightKg = 65.0,
    this.complexion = '',
    required this.education,
    required this.educationTier,
    this.occupation = '',
    required this.sect,
    required this.caste,
    required this.city,
    this.address = '',
    required this.contactNumber,
    this.fatherName = '',
    this.fatherOccupation = '',
    this.motherName = '',
    required this.agentReferenceName,
    required this.notes,
  });

  /// Convert into a Candidate instance ready for saving
  Candidate toCandidate({
    required String id,
    String? photoPath,
    String? photo2Path,
    String? photo3Path,
    String? biodataImagePath,
  }) {
    return Candidate(
      id: id,
      name: name.isNotEmpty ? name : 'New Candidate',
      gender: gender.isNotEmpty ? gender : 'Male',
      dob: dob,
      age: age > 0 ? age : 25,
      heightInches: heightInches > 0 ? heightInches : 67.0,
      heightDisplay: heightDisplay.isNotEmpty ? heightDisplay : "5' 7\"",
      weightKg: weightKg > 0 ? weightKg : 65.0,
      complexion: complexion,
      education: education.isNotEmpty ? education : 'Graduate',
      educationTier: educationTier,
      occupation: occupation,
      sect: sect.isNotEmpty ? sect : 'Sunni',
      caste: caste.isNotEmpty ? caste : 'General',
      city: city.isNotEmpty ? city : 'Not Specified',
      address: address,
      contactNumber: contactNumber,
      fatherName: fatherName,
      fatherOccupation: fatherOccupation,
      motherName: motherName,
      agentReferenceName: agentReferenceName.isNotEmpty ? agentReferenceName : 'Direct',
      photoPath: photoPath,
      photo2Path: photo2Path,
      photo3Path: photo3Path,
      biodataImagePath: biodataImagePath,
      pipelineStatus: PipelineStage.pendingReview,
      notes: notes,
    );
  }
}

/// Robust heuristic & regular expression parser for South Asian Muslim biodatas
class BiodataOcrParser {
  static const List<String> knownSects = [
    'Tablighi', 'Ahle Hadith', 'Ahle-Hadith', 'Ahle Hadees', 'Salafi',
    'Barelvi', 'Bareillvi', 'Deobandi', 'Sunni', 'Hanafi', 'Shia', 'Ithna Ashari',
  ];

  static const List<String> knownCastes = [
    'Syed', 'Sayed', 'Sheikh', 'Shaikh', 'Rajput', 'Arain', 'Ansari',
    'Memon', 'Gujjar', 'Malik', 'Mughal', 'Qureshi', 'Khan', 'Pathan',
    'Pashtun', 'Siddiqui', 'Farooqi', 'Alvi', 'Usmani', 'Butt', 'Jatt',
    'Jat', 'Chaudhary', 'Bhat', 'Kashmiri', 'Abbasi', 'Mirza', 'Hashmi',
    'Kazmi', 'Zaidi', 'Rizvi', 'Bohra', 'Khoja',
    // Indian South Asian castes from uploaded biodatas
    'Melmuri', 'Hosuri', 'Mujawar', 'Nadaf', 'Belagavi', 'Pathan',
  ];

  static const List<String> commonCities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Multan',
    'Peshawar', 'Quetta', 'Sialkot', 'Gujranwala', 'Hyderabad',
    'Delhi', 'Mumbai', 'Lucknow', 'Bangalore', 'Chennai', 'Kolkata',
    'Ahmedabad', 'Hubli', 'Dharwad', 'Hubli-Dharwad', 'Gokak', 'Belagavi',
    'Ramdurg', 'Malegaon', 'Pune', 'Nagpur',
    'Dubai', 'Abu Dhabi', 'Sharjah', 'Riyadh', 'Jeddah', 'Doha',
    'London', 'Manchester', 'Birmingham', 'Toronto', 'New York', 'Chicago',
  ];

  // Section heading keywords — lines matching these are NOT names
  static const List<String> _sectionHeadings = [
    'personal', 'details', 'family', 'background', 'qualification',
    'profession', 'education', 'siblings', 'residential', 'address',
    'contact', 'marriage', 'biodata', 'bismillah', 'allah', 'raheem',
    'proposal', 'profile', 'resume', 'curriculum', 'vitae',
  ];

  static ParsedBiodataResult parse(String rawOcrText) {
    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final family = _extractFamilyInfo(lines, rawOcrText);
    final cutoff = family.cutoff;

    final name = _extractName(lines, rawOcrText, cutoff);
    final gender = _extractGender(lines, rawOcrText);
    final dob = _extractDob(lines, rawOcrText);
    final age = _extractAge(lines, rawOcrText, dob);
    final heightData = _extractHeight(lines, rawOcrText);
    final weight = _extractWeight(lines, rawOcrText);
    final complexion = _extractComplexion(lines, rawOcrText);
    final education = _extractEducation(lines, rawOcrText);
    final educationTier = EducationTier.fromString(education);
    final occupation = _extractOccupation(lines, rawOcrText, cutoff);
    final sect = _extractSect(lines, rawOcrText);
    final caste = _extractCaste(lines, rawOcrText);
    final city = _extractCity(lines, rawOcrText);
    final address = _extractAddress(lines, rawOcrText);
    final contact = _extractContact(lines, rawOcrText);
    final fatherName = family.fatherName;
    final fatherOcc = family.fatherOccupation;
    final motherName = family.motherName;
    final agent = _extractAgentReference(lines, rawOcrText);

    return ParsedBiodataResult(
      rawText: rawOcrText,
      name: name,
      gender: gender,
      dob: dob,
      age: age,
      heightInches: heightData.inches,
      heightDisplay: heightData.display,
      weightKg: weight,
      complexion: complexion,
      education: education,
      educationTier: educationTier,
      occupation: occupation,
      sect: sect,
      caste: caste,
      city: city,
      address: address,
      contactNumber: contact,
      fatherName: fatherName,
      fatherOccupation: fatherOcc,
      motherName: motherName,
      agentReferenceName: agent,
      notes: 'Auto-extracted from uploaded biodata on ${DateTime.now().toLocal()}',
    );
  }

  // ─────────────────────────────────────────────
  // NAME — label-based, then fallback heuristic
  // ─────────────────────────────────────────────
  static String _extractName(List<String> lines, String fullText, [int cutoffIndex = -1]) {
    final candidateLines = (cutoffIndex > 0) ? lines.sublist(0, cutoffIndex) : lines;
    final candidateText = candidateLines.join('\n');

    // 1. Label-based: "Candidate Name:", "Boy Name:", "Girl Name:", "Full Name:", "Name:"
    // Ensure negative lookbehinds so "Father's Name:" or "Mother's Name:" never match
    final labelPatterns = [
      RegExp(r'(?:candidate(?:\x27s)?|applicant|boy(?:\x27s)?|girl(?:\x27s)?|bride(?:\x27s)?|groom(?:\x27s)?)\s*name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{2,40})', caseSensitive: false),
      RegExp(r'(?:full\s*name)\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{2,40})', caseSensitive: false),
      RegExp(r'(?<!father\s*)(?<!father\x27s\s*)(?<!mother\s*)(?<!mother\x27s\s*)(?<!brother\s*)(?<!sister\s*)\bname\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{2,40})', caseSensitive: false),
    ];
    for (final pat in labelPatterns) {
      final m = pat.firstMatch(candidateText);
      if (m != null) {
        var val = m.group(1)!.trim();
        val = val.split(RegExp(r'[\n\r\d]|(?:\b(?:date|age|height|gender|dob|marital|born|s\/o|d\/o)\b)', caseSensitive: false)).first.trim();
        val = val.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
        if (val.split(RegExp(r'\s+')).length >= 2 && val.length > 4) {
          return _toTitleCase(val.replaceAll(RegExp(r'\s+'), ' '));
        }
      }
    }

    // 2. Fallback: first short line in candidate lines that looks like a person's name
    for (final line in candidateLines.take(15)) {
      final trimmed = line.trim();
      if (trimmed.length < 4 || trimmed.length > 40) continue;
      final lower = trimmed.toLowerCase();
      if (_sectionHeadings.any((h) => lower.contains(h))) continue;
      if (RegExp(r'\b(?:father|mother|brother|sister|qualification|education|height|weight)\b', caseSensitive: false).hasMatch(lower)) continue;
      if (RegExp(r'[\d:@#\-\/|(){}[\]]').hasMatch(trimmed)) continue;
      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 5) {
        if (words.every((w) => RegExp(r'^[A-Za-z\.]+$').hasMatch(w) && w.length > 1)) {
          return _toTitleCase(trimmed);
        }
      }
    }

    return '';
  }

  // ─────────────────────────────────────────────
  // DATE OF BIRTH
  // ─────────────────────────────────────────────
  static String _extractDob(List<String> lines, String fullText) {
    final patterns = [
      // "Date of Birth: 06 March 1997" / "DOB: 30-09-1999"
      RegExp(
        r'(?:date\s*of\s*birth|dob|d\.o\.b|born)\s*[:\-|]\s*'
        r'(\d{1,2}[\s\/\-\.th]?(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?|\d{1,2})[\s\/\-\.]*\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:date\s*of\s*birth|dob)\s*[:\-|]\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:date\s*of\s*birth|dob)\s*[:\-|]\s*(\d{1,2}\s+\w+\s+\d{4})',
        caseSensitive: false,
      ),
    ];
    for (final pat in patterns) {
      final m = pat.firstMatch(fullText);
      if (m != null) return m.group(1)!.trim();
    }
    return '';
  }

  // ─────────────────────────────────────────────
  // AGE (uses DOB year as secondary source)
  // ─────────────────────────────────────────────
  static int _extractAge(List<String> lines, String fullText, String dob) {
    // 1. Explicit age label
    final ageRegex = RegExp(r'age\s*[:\-|]\s*(\d{2})\b(?:\s*(?:years?|yrs?))?', caseSensitive: false);
    final m = ageRegex.firstMatch(fullText);
    if (m != null) return int.tryParse(m.group(1)!) ?? 0;

    // 2. From extracted DOB year
    if (dob.isNotEmpty) {
      final yearMatch = RegExp(r'(19\d{2}|200\d|201\d)').firstMatch(dob);
      if (yearMatch != null) {
        final year = int.tryParse(yearMatch.group(1)!);
        if (year != null) return DateTime.now().year - year;
      }
    }

    // 3. From DOB in full text
    final dobYearRegex = RegExp(
      r'(?:dob|date\s+of\s+birth|born)\s*[:\-|]\s*.*?(19\d{2}|200\d|201\d)',
      caseSensitive: false,
    );
    final dobM = dobYearRegex.firstMatch(fullText);
    if (dobM != null) {
      final year = int.tryParse(dobM.group(1)!);
      if (year != null) return DateTime.now().year - year;
    }

    // 4. Loose: "26 yrs" / "28 years old"
    final loose = RegExp(r'\b(1[8-9]|2\d|3[0-9]|4[0-9]|5[0-5])\s*(?:yrs|years)\b', caseSensitive: false);
    final lm = loose.firstMatch(fullText);
    if (lm != null) return int.tryParse(lm.group(1)!) ?? 0;

    return 26;
  }

  // ─────────────────────────────────────────────
  // HEIGHT — handles all real-world formats
  // ─────────────────────────────────────────────
  static _HeightResult _extractHeight(List<String> lines, String fullText) {
    // Try with label prefix first (more reliable), then without
    final patterns = <RegExp>[
      // "Height: 5 ft 5 inches" / "Height: 5 feet 1 inch"
      RegExp(r'(?:height|ht)\s*[:\-|]?\s*([4-7])\s*(?:ft|feet|foot)\s*([0-9]|1[0-1])\s*(?:inch(?:es)?|in\.?|")?', caseSensitive: false),
      // "Height: 5'11\"" or "Height: 5' 11\""
      RegExp("(?:height|ht)\\s*[:\\-|]?\\s*([4-7])\\s*['\"'\\u2032]\\s*([0-9]|1[0-1])\\s*[\"'\\u2033]?", caseSensitive: false),
      // "Height: 5.8 ft" (decimal feet)
      RegExp(r'(?:height|ht)\s*[:\-|]?\s*([4-7])\.([0-9]|1[0-1])\s*(?:ft|feet|foot)', caseSensitive: false),
      // Without label: "5 ft 5 inches"
      RegExp(r'\b([4-7])\s*(?:ft|feet|foot)\s*([0-9]|1[0-1])\s*(?:inch(?:es)?|in\.?|")?', caseSensitive: false),
      // Without label: "5'11\"" or "5' 11"
      RegExp("\\b([4-7])\\s*['\"'\\u2032]\\s*([0-9]|1[0-1])\\s*[\"'\\u2033]?", caseSensitive: false),
      // cm: "155 cm" or "175cm"
      RegExp(r'\b(1[4-9]\d)\s*cm\b', caseSensitive: false),
    ];

    for (final pat in patterns) {
      final m = pat.firstMatch(fullText);
      if (m == null) continue;
      // cm pattern
      if (pat.pattern.contains('cm')) {
        final cm = double.tryParse(m.group(1)!) ?? 170.0;
        final totalIn = cm / 2.54;
        final ft = (totalIn / 12).floor();
        final inch = (totalIn % 12).round();
        return _HeightResult(totalIn, "$ft' $inch\"");
      }
      final ft = int.tryParse(m.group(1)!) ?? 5;
      final inch = int.tryParse(m.group(2)!) ?? 0;
      // Sanity check: 4-7 feet, 0-11 inches
      if (ft >= 4 && ft <= 7 && inch >= 0 && inch <= 11) {
        return _HeightResult((ft * 12.0) + inch, "$ft' $inch\"");
      }
    }

    return _HeightResult(67.0, "5' 7\"");
  }

  // ─────────────────────────────────────────────
  // COMPLEXION
  // ─────────────────────────────────────────────
  static String _extractComplexion(List<String> lines, String fullText) {
    final pat = RegExp(r'(?:complexion|color|colour|skin)\s*[:\-|]\s*(\w+)', caseSensitive: false);
    final m = pat.firstMatch(fullText);
    return m != null ? _toTitleCase(m.group(1)!.trim()) : '';
  }

  // ─────────────────────────────────────────────
  // EDUCATION
  // ─────────────────────────────────────────────
  static String _extractEducation(List<String> lines, String fullText) {
    final patterns = [
      RegExp(r'(?:qualification|education|highest\s*education|degree|studies)\s*[:\-|]\s*([^\n\r]{4,80})', caseSensitive: false),
    ];
    for (final pat in patterns) {
      final m = pat.firstMatch(fullText);
      if (m != null) {
        final val = m.group(1)!.trim().split('\n').first.trim();
        if (val.isNotEmpty && val.length > 3) return val;
      }
    }

    // Token search fallback
    final tokens = [
      'PhD', 'Doctorate', 'MBBS', 'FCPS', 'MD', 'MS', 'M.Tech', 'MBA',
      'M.Com', 'M.Sc', 'MA', 'BE', 'B.Tech', 'B.E', 'BS CS', 'BS IT', 'BS',
      'BSc', 'B.Com', 'BBA', 'LLB', 'BDS', 'B.Com', 'Diploma', 'FSc', 'FA',
      'ICS', 'A-Levels', 'Matric', 'O-Levels',
    ];
    for (final token in tokens) {
      if (RegExp('\\b${RegExp.escape(token)}\\b', caseSensitive: false).hasMatch(fullText)) {
        return token;
      }
    }

    return 'Graduate';
  }

  // ─────────────────────────────────────────────
  // OCCUPATION — Candidate-only scope (strictly excludes father/family lines)
  // ─────────────────────────────────────────────
  static String _extractOccupation(List<String> lines, String fullText, [int cutoffIndex = -1]) {
    // Only search lines strictly before the father/family section
    final candidateLines = (cutoffIndex > 0) ? lines.sublist(0, cutoffIndex) : lines;

    // 1. Search candidate lines for explicit candidate occupation/profession/job
    for (final line in candidateLines) {
      final m = RegExp(
        r'(?:candidate(?:\x27s)?\s*occupation|boy(?:\x27s)?\s*occupation|girl(?:\x27s)?\s*occupation|occupation|profession|job|designation|working\s*as|employed\s*as|work\s*as)\s*[:\-|]\s*([^\n\r]{3,80})',
        caseSensitive: false,
      ).firstMatch(line);
      if (m != null) {
        final occ = m.group(1)!.trim().replaceAll(RegExp(r'[^\w\s\.\(\)\/\-]'), '').trim();
        if (occ.isNotEmpty) return _toTitleCase(occ);
      }
    }

    // 2. Search for company / working at
    for (final line in candidateLines) {
      final m = RegExp(
        r'(?:working\s*at|employed\s*at|company)\s*[:\-|]\s*([^\n\r]{3,80})',
        caseSensitive: false,
      ).firstMatch(line);
      if (m != null) {
        final occ = m.group(1)!.trim();
        if (occ.isNotEmpty) return _toTitleCase(occ);
      }
    }

    // Candidate has no explicit occupation in candidate section -> return empty
    // NEVER fall back to lines under Father/Family section!
    return '';
  }

  // ─────────────────────────────────────────────
  // SECT
  // ─────────────────────────────────────────────
  static String _extractSect(List<String> lines, String fullText) {
    final sectLabel = RegExp(r'(?:sect|maslak|religion)\s*[:\-|]\s*([a-zA-Z\s\-]+)', caseSensitive: false);
    final m = sectLabel.firstMatch(fullText);
    if (m != null) {
      final parsed = m.group(1)!.trim();
      for (final s in knownSects) {
        if (parsed.toLowerCase().contains(s.toLowerCase())) return _normalizeSect(s);
      }
    }
    for (final s in knownSects) {
      if (RegExp('\\b${RegExp.escape(s)}\\b', caseSensitive: false).hasMatch(fullText)) {
        return _normalizeSect(s);
      }
    }
    // If "Islam" or "Muslim" present but no sect specified, use Sunni
    if (RegExp(r'\b(?:islam|muslim)\b', caseSensitive: false).hasMatch(fullText)) return 'Sunni';
    return 'Sunni';
  }

  static String _normalizeSect(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('tabligh')) return 'Tablighi';
    if (lower.contains('hadith') || lower.contains('hadees') || lower.contains('salafi')) return 'Ahle Hadith';
    if (lower.contains('barelvi') || lower.contains('bareillvi')) return 'Barelvi';
    if (lower.contains('deoband')) return 'Deobandi';
    if (lower.contains('shia')) return 'Shia';
    return 'Sunni';
  }

  // ─────────────────────────────────────────────
  // CASTE
  // ─────────────────────────────────────────────
  static String _extractCaste(List<String> lines, String fullText) {
    final castePat = RegExp(r'(?:caste|biradari|clan|family\s*background)\s*[:\-|]\s*([a-zA-Z\s\-]+)', caseSensitive: false);
    final m = castePat.firstMatch(fullText);
    if (m != null) {
      final parsed = m.group(1)!.trim();
      for (final c in knownCastes) {
        if (parsed.toLowerCase().contains(c.toLowerCase())) return c;
      }
      return parsed.split(' ').first;
    }
    for (final c in knownCastes) {
      if (RegExp('\\b${RegExp.escape(c)}\\b', caseSensitive: false).hasMatch(fullText)) return c;
    }
    return 'General';
  }

  // ─────────────────────────────────────────────
  // CITY
  // ─────────────────────────────────────────────
  static String _extractCity(List<String> lines, String fullText) {
    final cityPat = RegExp(r'(?:city|place\s*of\s*birth|location|residence|living\s*in)\s*[:\-|]\s*([a-zA-Z\s\-]+)', caseSensitive: false);
    final m = cityPat.firstMatch(fullText);
    if (m != null) {
      final parsed = m.group(1)!.trim();
      for (final city in commonCities) {
        if (parsed.toLowerCase().contains(city.toLowerCase())) return city;
      }
      return parsed.split(',').first.trim();
    }
    for (final city in commonCities) {
      if (RegExp('\\b${RegExp.escape(city)}\\b', caseSensitive: false).hasMatch(fullText)) return city;
    }
    return 'Not Specified';
  }

  // ─────────────────────────────────────────────
  // ADDRESS
  // ─────────────────────────────────────────────
  static String _extractAddress(List<String> lines, String fullText) {
    final pat = RegExp(r'(?:house\s*address|residential\s*address|address)\s*[:\-|]\s*(.{10,120})', caseSensitive: false);
    final m = pat.firstMatch(fullText);
    if (m != null) return m.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    return '';
  }

  // ─────────────────────────────────────────────
  // CONTACT
  // ─────────────────────────────────────────────
  static String _extractContact(List<String> lines, String fullText) {
    final phonePat = RegExp(
      r'(?:contact|phone|mobile|whatsapp|tel)(?:\s*no\.?|\s*number)?\s*[:\-|]?\s*([+\d][\d\s\-]{7,14})',
      caseSensitive: false,
    );
    final m = phonePat.firstMatch(fullText);
    if (m != null) return m.group(1)!.trim();

    // Generic phone pattern fallback
    final genericPhone = RegExp(r'\b(\+?[\d]{10,13})\b');
    final gm = genericPhone.firstMatch(fullText);
    if (gm != null) return gm.group(1)!.trim();

    return '';
  }

  // ─────────────────────────────────────────────
  // FAMILY DETAILS (Father Name, Father Occupation, Mother Name)
  // ─────────────────────────────────────────────
  static _FamilyInfo _extractFamilyInfo(List<String> lines, String fullText) {
    int fatherIdx = -1;
    int motherIdx = -1;
    int familySectionIdx = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();
      if (familySectionIdx == -1 &&
          RegExp(r'^\s*(?:family\s*(?:details|background|info)|parents?\s*(?:details|info))\b', caseSensitive: false).hasMatch(lower)) {
        familySectionIdx = i;
      }
      if (fatherIdx == -1 &&
          (RegExp(r'\b(?:father(?:\x27s)?(?:\s*name)?|father)\b\s*[:\-|]', caseSensitive: false).hasMatch(line) ||
           RegExp(r'^\s*father(?:\x27s)?\s*[:\-|]', caseSensitive: false).hasMatch(line) ||
           RegExp(r'\b(?:s\/o|son\s+of)\b\s*[:\-|]?', caseSensitive: false).hasMatch(line))) {
        fatherIdx = i;
      }
      if (motherIdx == -1 &&
          (RegExp(r'\b(?:mother(?:\x27s)?(?:\s*name)?|mother)\b\s*[:\-|]', caseSensitive: false).hasMatch(line) ||
           RegExp(r'^\s*mother(?:\x27s)?\s*[:\-|]', caseSensitive: false).hasMatch(line) ||
           RegExp(r'\b(?:d\/o|daughter\s+of)\b\s*[:\-|]?', caseSensitive: false).hasMatch(line))) {
        motherIdx = i;
      }
    }

    String fatherName = '';
    String fatherOcc = '';
    String motherName = '';

    // Extract Father Name & inline occupation
    if (fatherIdx != -1) {
      final line = lines[fatherIdx];
      final m = RegExp(r'(?:father(?:\x27s)?(?:\s*name)?|father|s\/o|son\s+of)\s*[:\-|]?\s*([^\n\r]+)', caseSensitive: false).firstMatch(line);
      if (m != null) {
        final rawFather = m.group(1)!.trim();
        // Check for parenthesized occupation e.g. "Abdul Qadir (Project Engineer)"
        final paren = RegExp(r'^([^\(\)]+)\s*\((.+)\)$').firstMatch(rawFather);
        if (paren != null) {
          fatherName = paren.group(1)!.trim();
          fatherOcc = paren.group(2)!.trim();
        } else {
          final dash = RegExp(r'^([^\-]+)\s*-\s*([A-Za-z\s]+)$').firstMatch(rawFather);
          if (dash != null && dash.group(2)!.trim().length > 3) {
            fatherName = dash.group(1)!.trim();
            fatherOcc = dash.group(2)!.trim();
          } else {
            fatherName = rawFather;
          }
        }
      }

      // Check next 1-3 lines for Father's Occupation if not found inline
      // South Asian biodatas commonly put "Occupation: Project Engineer" right below Father Name
      if (fatherOcc.isEmpty) {
        for (int j = fatherIdx + 1; j < lines.length && j <= fatherIdx + 3; j++) {
          final nextLine = lines[j].trim();
          // Stop if reached mother or next section
          if (RegExp(r'\b(?:mother|siblings?|brothers?|sisters?|address|contact|phone)\b', caseSensitive: false).hasMatch(nextLine)) {
            break;
          }
          final occMatch = RegExp(
            r'^(?:occupation|profession|job|designation|business|working\s*as|service)\s*[:\-|]\s*(.+)$',
            caseSensitive: false,
          ).firstMatch(nextLine);
          if (occMatch != null) {
            fatherOcc = occMatch.group(1)!.trim();
            break;
          }
          final jobMatch = RegExp(
            r'^(?:businessman|business|govt\s*employee|govt\s*service|private\s*service|project\s*engineer|civil\s*engineer|engineer|doctor|teacher|professor|advocate|lawyer|farmer|agriculturist|retired|contractor|merchant|self\s*employed)$',
            caseSensitive: false,
          ).firstMatch(nextLine);
          if (jobMatch != null) {
            fatherOcc = jobMatch.group(0)!.trim();
            break;
          }
        }
      }
    } else {
      // Fallback single line regex
      final pat = RegExp(r"father'?s?\s*name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{3,40})", caseSensitive: false);
      final m = pat.firstMatch(fullText);
      if (m != null) fatherName = m.group(1)!.trim().split('\n').first.trim();

      final occPat = RegExp(r"father'?s?\s*(?:occupation|profession|job)\s*[:\-|]\s*(.{4,60})", caseSensitive: false);
      final om = occPat.firstMatch(fullText);
      if (om != null) fatherOcc = om.group(1)!.trim().split('\n').first.trim();
    }

    // Extract Mother Name
    if (motherIdx != -1) {
      final line = lines[motherIdx];
      final m = RegExp(r'(?:mother(?:\x27s)?(?:\s*name)?|mother|d\/o|daughter\s+of)\s*[:\-|]?\s*([^\n\r]+)', caseSensitive: false).firstMatch(line);
      if (m != null) {
        motherName = m.group(1)!.trim().split(RegExp(r'[\(\-]')).first.trim();
      }
    } else {
      final pat = RegExp(r"mother'?s?\s*name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{3,40})", caseSensitive: false);
      final m = pat.firstMatch(fullText);
      if (m != null) motherName = m.group(1)!.trim().split('\n').first.trim();
    }

    // Clean special chars & format
    fatherName = fatherName.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
    motherName = motherName.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
    fatherOcc = fatherOcc.replaceAll(RegExp(r'[^\w\s\.\(\)\/\-]'), '').trim();

    return _FamilyInfo(
      fatherName: _toTitleCase(fatherName),
      fatherOccupation: _toTitleCase(fatherOcc),
      motherName: _toTitleCase(motherName),
      fatherLineIndex: fatherIdx,
      familySectionIndex: familySectionIdx,
    );
  }

  // ─────────────────────────────────────────────
  // WEIGHT
  // ─────────────────────────────────────────────
  static double _extractWeight(List<String> lines, String fullText) {
    final kgPat = RegExp(r'(?:weight\s*[:\-|]\s*)?(\d{2,3})\s*(?:kg|kgs|kilos)\b', caseSensitive: false);
    final m = kgPat.firstMatch(fullText);
    if (m != null) return double.tryParse(m.group(1)!) ?? 65.0;
    final lbsPat = RegExp(r'(\d{2,3})\s*lbs\b', caseSensitive: false);
    final lm = lbsPat.firstMatch(fullText);
    if (lm != null) return ((double.tryParse(lm.group(1)!) ?? 140.0) * 0.453592).roundToDouble();
    return 65.0;
  }

  // ─────────────────────────────────────────────
  // AGENT REFERENCE
  // ─────────────────────────────────────────────
  static String _extractAgentReference(List<String> lines, String fullText) {
    final pat = RegExp(r'(?:agent|reference|ref|referred\s*by|contact\s*person)\s*[:\-|]\s*([a-zA-Z\s\.]+)', caseSensitive: false);
    final m = pat.firstMatch(fullText);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.isNotEmpty && name.length > 2) return name;
    }
    return 'Self / Direct Bureau';
  }

  // ─────────────────────────────────────────────
  // GENDER
  // ─────────────────────────────────────────────
  static String _extractGender(List<String> lines, String fullText) {
    final genderPat = RegExp(r'gender\s*[:\-|]\s*(male|female)', caseSensitive: false);
    final m = genderPat.firstMatch(fullText);
    if (m != null) return m.group(1)!.toLowerCase().contains('female') ? 'Female' : 'Male';

    final lower = fullText.toLowerCase();
    if (lower.contains('bride') || lower.contains('female') || lower.contains(' d/o ') ||
        lower.contains('daughter of') || lower.contains('unmarried girl')) return 'Female';
    if (lower.contains('groom') || lower.contains('male') || lower.contains(' s/o ') ||
        lower.contains('son of')) return 'Male';
    return 'Male';
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  static String _toTitleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _HeightResult {
  final double inches;
  final String display;
  _HeightResult(this.inches, this.display);
}

class _FamilyInfo {
  final String fatherName;
  final String fatherOccupation;
  final String motherName;
  final int fatherLineIndex;
  final int familySectionIndex;

  _FamilyInfo({
    this.fatherName = '',
    this.fatherOccupation = '',
    this.motherName = '',
    this.fatherLineIndex = -1,
    this.familySectionIndex = -1,
  });

  int get cutoff {
    if (familySectionIndex != -1 && fatherLineIndex != -1) {
      return familySectionIndex < fatherLineIndex ? familySectionIndex : fatherLineIndex;
    }
    if (familySectionIndex != -1) return familySectionIndex;
    if (fatherLineIndex != -1) return fatherLineIndex;
    return -1;
  }
}

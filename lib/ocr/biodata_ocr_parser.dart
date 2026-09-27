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

    final name = _extractName(lines, rawOcrText);
    final gender = _extractGender(lines, rawOcrText);
    final dob = _extractDob(lines, rawOcrText);
    final age = _extractAge(lines, rawOcrText, dob);
    final heightData = _extractHeight(lines, rawOcrText);
    final weight = _extractWeight(lines, rawOcrText);
    final complexion = _extractComplexion(lines, rawOcrText);
    final education = _extractEducation(lines, rawOcrText);
    final educationTier = EducationTier.fromString(education);
    final occupation = _extractOccupation(lines, rawOcrText);
    final sect = _extractSect(lines, rawOcrText);
    final caste = _extractCaste(lines, rawOcrText);
    final city = _extractCity(lines, rawOcrText);
    final address = _extractAddress(lines, rawOcrText);
    final contact = _extractContact(lines, rawOcrText);
    final fatherName = _extractFatherName(lines, rawOcrText);
    final fatherOcc = _extractFatherOccupation(lines, rawOcrText);
    final motherName = _extractMotherName(lines, rawOcrText);
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
  static String _extractName(List<String> lines, String fullText) {
    // 1. Label-based: "Full Name:", "Name:", "Candidate Name:"
    final labelPatterns = [
      RegExp(r'(?:full\s*name|name)\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{2,40})', caseSensitive: false),
      RegExp(r'(?:candidate|applicant|boy|girl|bride|groom)\s*(?:\'s\s*)?name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{2,40})', caseSensitive: false),
    ];
    for (final pat in labelPatterns) {
      final m = pat.firstMatch(fullText);
      if (m != null) {
        var val = m.group(1)!.trim();
        // Stop at first digit, newline, or stop-keyword
        val = val.split(RegExp(r'[\n\r\d]|(?:\b(?:date|age|height|gender|dob|marital|born|s\/o|d\/o)\b)', caseSensitive: false)).first.trim();
        val = val.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
        if (val.split(RegExp(r'\s+')).length >= 2 && val.length > 4) {
          return _toTitleCase(val.replaceAll(RegExp(r'\s+'), ' '));
        }
      }
    }

    // 2. Fallback: first short ALL-CAPS or title-case line that looks like a name
    for (final line in lines.take(15)) {
      final trimmed = line.trim();
      if (trimmed.length < 4 || trimmed.length > 40) continue;
      // Skip section headings
      final lower = trimmed.toLowerCase();
      if (_sectionHeadings.any((h) => lower.contains(h))) continue;
      // Skip lines with digits or special chars
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
      RegExp(r"(?:height|ht)\s*[:\-|]?\s*([4-7])\s*['′']\s*([0-9]|1[0-1])\s*[\"″]?", caseSensitive: false),
      // "Height: 5.8 ft" (decimal feet)
      RegExp(r'(?:height|ht)\s*[:\-|]?\s*([4-7])\.([0-9]|1[0-1])\s*(?:ft|feet|foot)', caseSensitive: false),
      // Without label: "5 ft 5 inches"
      RegExp(r'\b([4-7])\s*(?:ft|feet|foot)\s*([0-9]|1[0-1])\s*(?:inch(?:es)?|in\.?|")?', caseSensitive: false),
      // Without label: "5'11\"" or "5' 11"
      RegExp(r"\b([4-7])\s*['′']\s*([0-9]|1[0-1])\s*[\"″]?"),
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
  // OCCUPATION
  // ─────────────────────────────────────────────
  static String _extractOccupation(List<String> lines, String fullText) {
    final patterns = [
      RegExp(r'(?:occupation|profession|job|working\s*as|employed\s*as)\s*[:\-|]\s*([^\n\r]{4,80})', caseSensitive: false),
    ];
    for (final pat in patterns) {
      final m = pat.firstMatch(fullText);
      if (m != null) {
        return m.group(1)!.trim().split('\n').first.trim();
      }
    }
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
  // FATHER NAME
  // ─────────────────────────────────────────────
  static String _extractFatherName(List<String> lines, String fullText) {
    final pat = RegExp(r"father'?s?\s*name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{3,40})", caseSensitive: false);
    final m = pat.firstMatch(fullText);
    if (m != null) return m.group(1)!.trim().split('\n').first.trim();
    return '';
  }

  // ─────────────────────────────────────────────
  // FATHER OCCUPATION
  // ─────────────────────────────────────────────
  static String _extractFatherOccupation(List<String> lines, String fullText) {
    final pat = RegExp(r"father'?s?\s*(?:occupation|profession|job)\s*[:\-|]\s*(.{4,60})", caseSensitive: false);
    final m = pat.firstMatch(fullText);
    if (m != null) return m.group(1)!.trim().split('\n').first.trim();
    return '';
  }

  // ─────────────────────────────────────────────
  // MOTHER NAME
  // ─────────────────────────────────────────────
  static String _extractMotherName(List<String> lines, String fullText) {
    final pat = RegExp(r"mother'?s?\s*name\s*[:\-|]\s*([A-Za-z][A-Za-z\s\.]{3,40})", caseSensitive: false);
    final m = pat.firstMatch(fullText);
    if (m != null) return m.group(1)!.trim().split('\n').first.trim();
    return '';
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

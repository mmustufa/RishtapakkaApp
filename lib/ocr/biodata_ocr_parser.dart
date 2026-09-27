import 'dart:math';
import '../models/candidate.dart';
import '../models/education_tier.dart';
import '../models/pipeline_stage.dart';

class ParsedBiodataResult {
  final String rawText;
  final String name;
  final String gender;
  final int age;
  final double heightInches;
  final String heightDisplay;
  final double weightKg;
  final String education;
  final EducationTier educationTier;
  final String sect;
  final String caste;
  final String city;
  final String contactNumber;
  final String agentReferenceName;
  final String notes;

  ParsedBiodataResult({
    required this.rawText,
    required this.name,
    required this.gender,
    required this.age,
    required this.heightInches,
    required this.heightDisplay,
    required this.weightKg,
    required this.education,
    required this.educationTier,
    required this.sect,
    required this.caste,
    required this.city,
    required this.contactNumber,
    required this.agentReferenceName,
    required this.notes,
  });

  /// Convert into a Candidate instance ready for saving
  Candidate toCandidate({
    required String id,
    String? photoPath,
    String? biodataImagePath,
  }) {
    return Candidate(
      id: id,
      name: name.isNotEmpty ? name : 'New Candidate',
      gender: gender.isNotEmpty ? gender : 'Male',
      age: age > 0 ? age : 25,
      heightInches: heightInches > 0 ? heightInches : 67.0, // Default 5'7"
      heightDisplay: heightDisplay.isNotEmpty ? heightDisplay : "5' 7\"",
      weightKg: weightKg > 0 ? weightKg : 65.0,
      education: education.isNotEmpty ? education : 'Graduate',
      educationTier: educationTier,
      sect: sect.isNotEmpty ? sect : 'Sunni',
      caste: caste.isNotEmpty ? caste : 'General',
      city: city.isNotEmpty ? city : 'Not Specified',
      contactNumber: contactNumber,
      agentReferenceName: agentReferenceName.isNotEmpty ? agentReferenceName : 'Direct',
      photoPath: photoPath,
      biodataImagePath: biodataImagePath,
      pipelineStatus: PipelineStage.pendingReview,
      notes: notes,
    );
  }
}

/// Robust heuristic & regular expression parser for South Asian Muslim biodatas
class BiodataOcrParser {
  static const List<String> knownSects = [
    'Tablighi',
    'Ahle Hadith',
    'Ahle-Hadith',
    'Ahle Hadees',
    'Salafi',
    'Barelvi',
    'Bareillvi',
    'Deobandi',
    'Sunni',
    'Hanafi',
    'Shia',
    'Ithna Ashari',
  ];

  static const List<String> knownCastes = [
    'Syed',
    'Sayed',
    'Sheikh',
    'Shaikh',
    'Rajput',
    'Arain',
    'Ansari',
    'Memon',
    'Gujjar',
    'Malik',
    'Mughal',
    'Qureshi',
    'Khan',
    'Pathan',
    'Pashtun',
    'Siddiqui',
    'Farooqi',
    'Alvi',
    'Usmani',
    'Butt',
    'Jatt',
    'Jat',
    'Chaudhary',
    'Bhat',
    'Kashmiri',
    'Abbasi',
    'Mirza',
    'Hashmi',
    'Kazmi',
    'Zaidi',
    'Rizvi',
    'Bohra',
    'Khoja',
  ];

  static const List<String> commonCities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Gujranwala',
    'Hyderabad',
    'Delhi',
    'Mumbai',
    'Lucknow',
    'Bangalore',
    'Chennai',
    'Kolkata',
    'Ahmedabad',
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Riyadh',
    'Jeddah',
    'Doha',
    'London',
    'Manchester',
    'Birmingham',
    'Toronto',
    'New York',
    'Chicago',
  ];

  static ParsedBiodataResult parse(String rawOcrText) {
    final lines = rawOcrText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String name = _extractName(lines, rawOcrText);
    String gender = _extractGender(lines, rawOcrText);
    int age = _extractAge(lines, rawOcrText);
    final heightData = _extractHeight(lines, rawOcrText);
    double weight = _extractWeight(lines, rawOcrText);
    String education = _extractEducation(lines, rawOcrText);
    EducationTier educationTier = EducationTier.fromString(education);
    String sect = _extractSect(lines, rawOcrText);
    String caste = _extractCaste(lines, rawOcrText);
    String city = _extractCity(lines, rawOcrText);
    String contact = _extractContact(lines, rawOcrText);
    String agent = _extractAgentReference(lines, rawOcrText);

    return ParsedBiodataResult(
      rawText: rawOcrText,
      name: name,
      gender: gender,
      age: age,
      heightInches: heightData.inches,
      heightDisplay: heightData.display,
      weightKg: weight,
      education: education,
      educationTier: educationTier,
      sect: sect,
      caste: caste,
      city: city,
      contactNumber: contact,
      agentReferenceName: agent,
      notes: 'Auto-extracted from uploaded biodata on ${DateTime.now().toLocal()}',
    );
  }

  // --- EXTRACTION SUB-MODULES ---

  static String _extractName(List<String> lines, String fullText) {
    // 1. Look for explicit labels
    final nameRegex = RegExp(
      r'(?:candidate|boy|girl|bride|groom|full)?\s*name\s*[:\-\=]\s*([a-zA-Z\s\.\,\(\)]+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = nameRegex.firstMatch(line);
      if (match != null) {
        final val = match.group(1)?.trim();
        if (val != null && val.length > 2 && !val.toLowerCase().contains('biodata')) {
          return _cleanName(val);
        }
      }
    }

    // 2. Look for "Biodata of [Name]"
    final bioOfRegex = RegExp(r'biodata\s+of\s+([a-zA-Z\s\.\,]+)', caseSensitive: false);
    final bioMatch = bioOfRegex.firstMatch(fullText);
    if (bioMatch != null) {
      final val = bioMatch.group(1)?.trim();
      if (val != null && val.isNotEmpty) return _cleanName(val);
    }

    // 3. Fallback: First line that is purely alphabetic (2-4 words) and not a header
    for (final line in lines.take(5)) {
      if (RegExp(r'^[a-zA-Z\s\.]{4,35}$').hasMatch(line)) {
        final lower = line.toLowerCase();
        if (!lower.contains('biodata') &&
            !lower.contains('curriculum') &&
            !lower.contains('resume') &&
            !lower.contains('marriage') &&
            !lower.contains('profile') &&
            !lower.contains('bismillah')) {
          return _cleanName(line);
        }
      }
    }

    return '';
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'[:\-\=]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _extractGender(List<String> lines, String fullText) {
    final lower = fullText.toLowerCase();

    // Check direct gender label
    final genderRegex = RegExp(r'gender\s*[:\-\=]\s*(male|female)', caseSensitive: false);
    final gMatch = genderRegex.firstMatch(fullText);
    if (gMatch != null) {
      return gMatch.group(1)!.toLowerCase().contains('female') ? 'Female' : 'Male';
    }

    // Heuristics: bride/girl/daughter vs groom/boy/son
    if (lower.contains('bride') ||
        lower.contains('girl') ||
        lower.contains('daughter of') ||
        lower.contains('d/o') ||
        lower.contains('female')) {
      return 'Female';
    }
    if (lower.contains('groom') ||
        lower.contains('boy') ||
        lower.contains('son of') ||
        lower.contains('s/o') ||
        lower.contains('male')) {
      return 'Male';
    }

    return 'Male'; // Default
  }

  static int _extractAge(List<String> lines, String fullText) {
    // 1. Explicit Age: "Age: 27", "Age: 25 Yrs", "Age - 28"
    final ageRegex = RegExp(
      r'age\s*[:\-\=]\s*(\d{2})\b(?:\s*(?:years?|yrs?))?',
      caseSensitive: false,
    );
    final match = ageRegex.firstMatch(fullText);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }

    // 2. Date of birth: "DOB: 15/08/1996", "Date of Birth: 1995"
    final dobRegex = RegExp(
      r'(?:dob|date\s+of\s+birth|born)\s*[:\-\=]\s*.*?(19\d{2}|200\d)',
      caseSensitive: false,
    );
    final dobMatch = dobRegex.firstMatch(fullText);
    if (dobMatch != null) {
      final year = int.tryParse(dobMatch.group(1)!);
      if (year != null) {
        return DateTime.now().year - year;
      }
    }

    // 3. Fallback: search for pattern like "26 yrs" or "28 years old"
    final looseRegex = RegExp(r'\b(2[0-9]|3[0-9]|4[0-9]|5[0-9])\s*(?:yrs|years)\b', caseSensitive: false);
    final looseMatch = looseRegex.firstMatch(fullText);
    if (looseMatch != null) {
      return int.tryParse(looseMatch.group(1)!) ?? 0;
    }

    return 26; // Reasonable fallback
  }

  static _HeightResult _extractHeight(List<String> lines, String fullText) {
    // 1. Pattern: 5'8" or 5' 10" or 5ft 8in or 5 ft 7 in
    final ftInRegex = RegExp(
      r'(?:height\s*[:\-\=]\s*)?([4-6])\s*(?:\'|ft|feet|\.)\s*([0-9]|1[0-1])(?:\s*(?:\"|in|inches))?',
      caseSensitive: false,
    );
    final match = ftInRegex.firstMatch(fullText);
    if (match != null) {
      final feet = int.tryParse(match.group(1)!) ?? 5;
      final inches = int.tryParse(match.group(2)!) ?? 0;
      final totalInches = (feet * 12.0) + inches;
      return _HeightResult(totalInches, "$feet' $inches\"");
    }

    // 2. Pattern in Centimeters: "172 cm", "168cm"
    final cmRegex = RegExp(r'(\d{3})\s*cm\b', caseSensitive: false);
    final cmMatch = cmRegex.firstMatch(fullText);
    if (cmMatch != null) {
      final cm = double.tryParse(cmMatch.group(1)!) ?? 170.0;
      final totalInches = cm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      return _HeightResult(totalInches, "$feet' $inches\"");
    }

    // Default: 5' 7" = 67 inches
    return _HeightResult(67.0, "5' 7\"");
  }

  static double _extractWeight(List<String> lines, String fullText) {
    final weightRegex = RegExp(
      r'(?:weight\s*[:\-\=]\s*)?(\d{2,3})\s*(?:kg|kgs|kilos)\b',
      caseSensitive: false,
    );
    final match = weightRegex.firstMatch(fullText);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 65.0;
    }

    // Lbs check
    final lbsRegex = RegExp(r'(\d{2,3})\s*lbs\b', caseSensitive: false);
    final lbsMatch = lbsRegex.firstMatch(fullText);
    if (lbsMatch != null) {
      final lbs = double.tryParse(lbsMatch.group(1)!) ?? 140.0;
      return (lbs * 0.453592).roundToDouble();
    }

    return 65.0;
  }

  static String _extractEducation(List<String> lines, String fullText) {
    final eduLabelRegex = RegExp(
      r'(?:qualification|education|degree|studies)\s*[:\-\=]\s*([^\n\r]+)',
      caseSensitive: false,
    );
    final match = eduLabelRegex.firstMatch(fullText);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Search for known degree tokens
    final tokens = [
      'PhD',
      'Doctorate',
      'MBBS',
      'FCPS',
      'MD',
      'MS',
      'M.Tech',
      'MBA',
      'M.Com',
      'M.Sc',
      'MA',
      'B.Tech',
      'BE',
      'BS CS',
      'BS IT',
      'BS',
      'BSc',
      'B.Com',
      'BBA',
      'LLB',
      'BDS',
      'FSc',
      'FA',
      'ICS',
      'A-Levels',
      'Matric',
      'O-Levels',
    ];

    for (final token in tokens) {
      if (RegExp('\\b$token\\b', caseSensitive: false).hasMatch(fullText)) {
        return token;
      }
    }

    return 'Graduate';
  }

  static String _extractSect(List<String> lines, String fullText) {
    // 1. Explicit label: "Sect: Barelvi", "Maslak: Ahle Hadith"
    final sectLabelRegex = RegExp(
      r'(?:sect|maslak|religion)\s*[:\-\=]\s*([a-zA-Z\s\-]+)',
      caseSensitive: false,
    );
    final match = sectLabelRegex.firstMatch(fullText);
    if (match != null) {
      final parsed = match.group(1)!.trim();
      for (final s in knownSects) {
        if (parsed.toLowerCase().contains(s.toLowerCase())) {
          return _normalizeSect(s);
        }
      }
    }

    // 2. Scan entire document for known sects
    for (final s in knownSects) {
      if (RegExp('\\b${RegExp.escape(s)}\\b', caseSensitive: false).hasMatch(fullText)) {
        return _normalizeSect(s);
      }
    }

    return 'Sunni'; // Default common
  }

  static String _normalizeSect(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('tabligh')) return 'Tablighi';
    if (lower.contains('hadith') || lower.contains('hadees') || lower.contains('salafi')) {
      return 'Ahle Hadith';
    }
    if (lower.contains('barelvi') || lower.contains('bareillvi')) return 'Barelvi';
    if (lower.contains('deoband')) return 'Deobandi';
    if (lower.contains('shia')) return 'Shia';
    return 'Sunni';
  }

  static String _extractCaste(List<String> lines, String fullText) {
    final casteLabelRegex = RegExp(
      r'(?:caste|biradari|clan|family)\s*[:\-\=]\s*([a-zA-Z\s\-]+)',
      caseSensitive: false,
    );
    final match = casteLabelRegex.firstMatch(fullText);
    if (match != null) {
      final parsed = match.group(1)!.trim();
      for (final c in knownCastes) {
        if (parsed.toLowerCase().contains(c.toLowerCase())) {
          return c;
        }
      }
      return parsed.split(' ').first;
    }

    // Match keywords anywhere
    for (final c in knownCastes) {
      if (RegExp('\\b${RegExp.escape(c)}\\b', caseSensitive: false).hasMatch(fullText)) {
        return c;
      }
    }

    return 'General';
  }

  static String _extractCity(List<String> lines, String fullText) {
    final cityLabelRegex = RegExp(
      r'(?:city|residence|location|address|native|living\s+in)\s*[:\-\=]\s*([a-zA-Z\s]+)',
      caseSensitive: false,
    );
    final match = cityLabelRegex.firstMatch(fullText);
    if (match != null) {
      final parsed = match.group(1)!.trim();
      for (final city in commonCities) {
        if (parsed.toLowerCase().contains(city.toLowerCase())) {
          return city;
        }
      }
      return parsed.split(',').first.trim();
    }

    for (final city in commonCities) {
      if (RegExp('\\b${RegExp.escape(city)}\\b', caseSensitive: false).hasMatch(fullText)) {
        return city;
      }
    }

    return 'Not Specified';
  }

  static String _extractContact(List<String> lines, String fullText) {
    final phoneRegex = RegExp(
      r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}',
    );
    final match = phoneRegex.firstMatch(fullText);
    if (match != null) {
      return match.group(0)!.trim();
    }
    return '';
  }

  static String _extractAgentReference(List<String> lines, String fullText) {
    final agentRegex = RegExp(
      r'(?:agent|reference|ref|referred\s*by|contact\s*person)\s*[:\-\=]\s*([a-zA-Z\s\.]+)',
      caseSensitive: false,
    );
    final match = agentRegex.firstMatch(fullText);
    if (match != null) {
      final name = match.group(1)!.trim();
      if (name.isNotEmpty && name.length > 2) {
        return name;
      }
    }
    return 'Self / Direct Bureau';
  }
}

class _HeightResult {
  final double inches;
  final String display;
  _HeightResult(this.inches, this.display);
}

import 'education_tier.dart';
import 'pipeline_stage.dart';

class Candidate {
  final String id;
  final String name;
  final String gender; // 'Male' or 'Female'
  final int age;
  final double heightInches; // For numerical comparison (e.g. 5'10" = 70.0 inches)
  final String heightDisplay; // User-facing string e.g. "5' 10\""
  final double weightKg;
  final String education; // Raw text e.g. "BS Software Engineering"
  final EducationTier educationTier;
  final String sect; // Maslak e.g. "Tablighi", "Ahle Hadith", "Barelvi", "Deobandi"
  final String caste; // Biradari e.g. "Sheikh", "Syed", "Rajput", "Ansari"
  final String city;
  final String contactNumber;
  final String agentReferenceName; // Mandatory: Submitting agent / bureau reference
  final String? photoPath; // Local internal storage file path
  final String? biodataImagePath; // Local internal storage path of original scan
  final PipelineStage pipelineStatus;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Candidate({
    required this.id,
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
    this.photoPath,
    this.biodataImagePath,
    this.pipelineStatus = PipelineStage.pendingReview,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isMale => gender.trim().toLowerCase() == 'male';
  bool get isFemale => gender.trim().toLowerCase() == 'female';

  Candidate copyWith({
    String? id,
    String? name,
    String? gender,
    int? age,
    double? heightInches,
    String? heightDisplay,
    double? weightKg,
    String? education,
    EducationTier? educationTier,
    String? sect,
    String? caste,
    String? city,
    String? contactNumber,
    String? agentReferenceName,
    String? photoPath,
    String? biodataImagePath,
    PipelineStage? pipelineStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightInches: heightInches ?? this.heightInches,
      heightDisplay: heightDisplay ?? this.heightDisplay,
      weightKg: weightKg ?? this.weightKg,
      education: education ?? this.education,
      educationTier: educationTier ?? this.educationTier,
      sect: sect ?? this.sect,
      caste: caste ?? this.caste,
      city: city ?? this.city,
      contactNumber: contactNumber ?? this.contactNumber,
      agentReferenceName: agentReferenceName ?? this.agentReferenceName,
      photoPath: photoPath ?? this.photoPath,
      biodataImagePath: biodataImagePath ?? this.biodataImagePath,
      pipelineStatus: pipelineStatus ?? this.pipelineStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'height_inches': heightInches,
      'height_display': heightDisplay,
      'weight_kg': weightKg,
      'education': education,
      'education_tier': educationTier.rank,
      'sect': sect,
      'caste': caste,
      'city': city,
      'contact_number': contactNumber,
      'agent_reference_name': agentReferenceName,
      'photo_path': photoPath,
      'biodata_image_path': biodataImagePath,
      'pipeline_status': pipelineStatus.key,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Candidate.fromMap(Map<String, dynamic> map) {
    return Candidate(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      gender: map['gender'] as String? ?? 'Male',
      age: (map['age'] as num?)?.toInt() ?? 25,
      heightInches: (map['height_inches'] as num?)?.toDouble() ?? 66.0,
      heightDisplay: map['height_display'] as String? ?? "5'6\"",
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 65.0,
      education: map['education'] as String? ?? 'Unspecified',
      educationTier: EducationTier.values.firstWhere(
        (t) => t.rank == (map['education_tier'] as int? ?? 0),
        orElse: () => EducationTier.unspecified,
      ),
      sect: map['sect'] as String? ?? 'Sunni',
      caste: map['caste'] as String? ?? 'General',
      city: map['city'] as String? ?? 'Not Specified',
      contactNumber: map['contact_number'] as String? ?? '',
      agentReferenceName: map['agent_reference_name'] as String? ?? 'Self',
      photoPath: map['photo_path'] as String?,
      biodataImagePath: map['biodata_image_path'] as String?,
      pipelineStatus: PipelineStage.fromKey(map['pipeline_status'] as String?),
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

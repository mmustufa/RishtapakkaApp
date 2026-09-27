import 'education_tier.dart';
import 'pipeline_stage.dart';

class Candidate {
  final String id;
  final String name;
  final String gender; // 'Male' or 'Female'
  final String dob;    // Date of birth as display string e.g. "06 March 1997"
  final int age;
  final double heightInches; // For numerical comparison (e.g. 5'10" = 70.0 inches)
  final String heightDisplay; // User-facing string e.g. "5' 10\""
  final double weightKg;
  final String complexion;
  final String education; // Raw text e.g. "BS Software Engineering"
  final EducationTier educationTier;
  final String occupation;
  final String sect; // Maslak e.g. "Tablighi", "Ahle Hadith", "Barelvi", "Deobandi"
  final String caste; // Biradari e.g. "Sheikh", "Syed", "Rajput", "Ansari"
  final String city;
  final String address;
  final String contactNumber;
  final String fatherName;
  final String fatherOccupation;
  final String motherName;
  final String agentReferenceName; // Mandatory: Submitting agent / bureau reference
  final String? photoPath;         // Profile photo (photo 1)
  final String? photo2Path;        // Additional photo 2
  final String? photo3Path;        // Additional photo 3
  final String? biodataImagePath;  // Local internal storage path of original scan
  final PipelineStage pipelineStatus;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Candidate({
    required this.id,
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
    this.contactNumber = '',
    this.fatherName = '',
    this.fatherOccupation = '',
    this.motherName = '',
    required this.agentReferenceName,
    this.photoPath,
    this.photo2Path,
    this.photo3Path,
    this.biodataImagePath,
    this.pipelineStatus = PipelineStage.pendingReview,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isMale => gender.trim().toLowerCase() == 'male';
  bool get isFemale => gender.trim().toLowerCase() == 'female';

  /// All uploaded photos as a list (non-null only)
  List<String> get allPhotos => [
    if (photoPath != null && photoPath!.isNotEmpty) photoPath!,
    if (photo2Path != null && photo2Path!.isNotEmpty) photo2Path!,
    if (photo3Path != null && photo3Path!.isNotEmpty) photo3Path!,
  ];

  Candidate copyWith({
    String? id,
    String? name,
    String? gender,
    String? dob,
    int? age,
    double? heightInches,
    String? heightDisplay,
    double? weightKg,
    String? complexion,
    String? education,
    EducationTier? educationTier,
    String? occupation,
    String? sect,
    String? caste,
    String? city,
    String? address,
    String? contactNumber,
    String? fatherName,
    String? fatherOccupation,
    String? motherName,
    String? agentReferenceName,
    String? photoPath,
    String? photo2Path,
    String? photo3Path,
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
      dob: dob ?? this.dob,
      age: age ?? this.age,
      heightInches: heightInches ?? this.heightInches,
      heightDisplay: heightDisplay ?? this.heightDisplay,
      weightKg: weightKg ?? this.weightKg,
      complexion: complexion ?? this.complexion,
      education: education ?? this.education,
      educationTier: educationTier ?? this.educationTier,
      occupation: occupation ?? this.occupation,
      sect: sect ?? this.sect,
      caste: caste ?? this.caste,
      city: city ?? this.city,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      fatherName: fatherName ?? this.fatherName,
      fatherOccupation: fatherOccupation ?? this.fatherOccupation,
      motherName: motherName ?? this.motherName,
      agentReferenceName: agentReferenceName ?? this.agentReferenceName,
      photoPath: photoPath ?? this.photoPath,
      photo2Path: photo2Path ?? this.photo2Path,
      photo3Path: photo3Path ?? this.photo3Path,
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
      'dob': dob,
      'age': age,
      'height_inches': heightInches,
      'height_display': heightDisplay,
      'weight_kg': weightKg,
      'complexion': complexion,
      'education': education,
      'education_tier': educationTier.rank,
      'occupation': occupation,
      'sect': sect,
      'caste': caste,
      'city': city,
      'address': address,
      'contact_number': contactNumber,
      'father_name': fatherName,
      'father_occupation': fatherOccupation,
      'mother_name': motherName,
      'agent_reference_name': agentReferenceName,
      'photo_path': photoPath,
      'photo2_path': photo2Path,
      'photo3_path': photo3Path,
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
      dob: map['dob'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 25,
      heightInches: (map['height_inches'] as num?)?.toDouble() ?? 66.0,
      heightDisplay: map['height_display'] as String? ?? "5'6\"",
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 65.0,
      complexion: map['complexion'] as String? ?? '',
      education: map['education'] as String? ?? 'Unspecified',
      educationTier: EducationTier.values.firstWhere(
        (t) => t.rank == (map['education_tier'] as int? ?? 0),
        orElse: () => EducationTier.unspecified,
      ),
      occupation: map['occupation'] as String? ?? '',
      sect: map['sect'] as String? ?? 'Sunni',
      caste: map['caste'] as String? ?? 'General',
      city: map['city'] as String? ?? 'Not Specified',
      address: map['address'] as String? ?? '',
      contactNumber: map['contact_number'] as String? ?? '',
      fatherName: map['father_name'] as String? ?? '',
      fatherOccupation: map['father_occupation'] as String? ?? '',
      motherName: map['mother_name'] as String? ?? '',
      agentReferenceName: map['agent_reference_name'] as String? ?? 'Self',
      photoPath: map['photo_path'] as String?,
      photo2Path: map['photo2_path'] as String?,
      photo3Path: map['photo3_path'] as String?,
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

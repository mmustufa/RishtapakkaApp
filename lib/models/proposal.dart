import 'pipeline_stage.dart';

class Proposal {
  final String id;
  final String maleCandidateId;
  final String femaleCandidateId;
  final String maleName;
  final String femaleName;
  final String sect;
  final String caste;
  final PipelineStage stage;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal({
    required this.id,
    required this.maleCandidateId,
    required this.femaleCandidateId,
    required this.maleName,
    required this.femaleName,
    required this.sect,
    required this.caste,
    this.stage = PipelineStage.proposalSent,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Proposal copyWith({
    String? id,
    String? maleCandidateId,
    String? femaleCandidateId,
    String? maleName,
    String? femaleName,
    String? sect,
    String? caste,
    PipelineStage? stage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Proposal(
      id: id ?? this.id,
      maleCandidateId: maleCandidateId ?? this.maleCandidateId,
      femaleCandidateId: femaleCandidateId ?? this.femaleCandidateId,
      maleName: maleName ?? this.maleName,
      femaleName: femaleName ?? this.femaleName,
      sect: sect ?? this.sect,
      caste: caste ?? this.caste,
      stage: stage ?? this.stage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'male_candidate_id': maleCandidateId,
      'female_candidate_id': femaleCandidateId,
      'male_name': maleName,
      'female_name': femaleName,
      'sect': sect,
      'caste': caste,
      'stage': stage.key,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Proposal.fromMap(Map<String, dynamic> map) {
    return Proposal(
      id: map['id'] as String,
      maleCandidateId: map['male_candidate_id'] as String,
      femaleCandidateId: map['female_candidate_id'] as String,
      maleName: map['male_name'] as String? ?? 'Male Candidate',
      femaleName: map['female_name'] as String? ?? 'Female Candidate',
      sect: map['sect'] as String? ?? '',
      caste: map['caste'] as String? ?? '',
      stage: PipelineStage.fromKey(map['stage'] as String?),
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

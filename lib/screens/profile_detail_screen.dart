import 'dart:io';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/candidate.dart';
import '../models/pipeline_stage.dart';
import '../widgets/status_badge.dart';
import 'candidate_matches_screen.dart';
import 'edit_candidate_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String candidateId;

  const ProfileDetailScreen({super.key, required this.candidateId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Candidate? _candidate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidate();
  }

  Future<void> _loadCandidate() async {
    setState(() => _isLoading = true);
    final c = await AppDatabase.instance.getCandidateById(widget.candidateId);
    setState(() {
      _candidate = c;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(PipelineStage stage) async {
    if (_candidate == null) return;
    final updated = _candidate!.copyWith(pipelineStatus: stage);
    await AppDatabase.instance.updateCandidate(updated);
    _loadCandidate();
  }

  Future<void> _deleteCandidate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Candidate?'),
        content: Text('Are you sure you want to delete "${_candidate?.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppDatabase.instance.deleteCandidate(widget.candidateId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_candidate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Candidate Not Found')),
        body: const Center(child: Text('This candidate does not exist in local SQLite.')),
      );
    }

    final c = _candidate!;
    final isMale = c.isMale;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCandidateScreen(candidate: c),
                ),
              );
              if (result == true) _loadCandidate();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteCandidate,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandidateMatchesScreen(targetCandidate: c),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMale ? const Color(0xFF1E3A8A) : const Color(0xFF9D174D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.favorite_rounded),
            label: const Text(
              'Find Matching Candidates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Profile Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: isMale ? Colors.blue.shade100 : Colors.pink.shade100,
                    child: Icon(
                      isMale ? Icons.man_rounded : Icons.woman_rounded,
                      size: 56,
                      color: isMale ? Colors.blue.shade800 : Colors.pink.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(stage: c.pipelineStatus),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pipeline Stage Quick Picker
            const Text(
              'Update Pipeline Stage:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: PipelineStage.values.map((s) {
                final isSelected = c.pipelineStatus == s;
                return ChoiceChip(
                  label: Text(s.displayName, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: s.color.withOpacity(0.2),
                  onSelected: (val) {
                    if (val) _updateStatus(s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Key Biodata Details Table
            _buildSectionCard(
              title: 'Personal & Physical Attributes',
              icon: Icons.person_outline_rounded,
              rows: [
                _detailRow('Gender', c.gender),
                _detailRow('Age', '${c.age} years'),
                _detailRow('Height', '${c.heightDisplay} (${c.heightInches.toStringAsFixed(1)} inches)'),
                _detailRow('Weight', '${c.weightKg.toStringAsFixed(0)} kg'),
                _detailRow('City / Location', c.city),
              ],
            ),
            const SizedBox(height: 12),

            _buildSectionCard(
              title: 'Religious & Community Heritage',
              icon: Icons.mosque_outlined,
              rows: [
                _detailRow('Sect (Maslak)', c.sect, isHighlight: true),
                _detailRow('Caste (Biradari)', c.caste, isHighlight: true),
              ],
            ),
            const SizedBox(height: 12),

            _buildSectionCard(
              title: 'Academic & Professional',
              icon: Icons.school_outlined,
              rows: [
                _detailRow('Education', c.education),
                _detailRow(
                  'Hierarchy Tier',
                  'Tier ${c.educationTier.rank} (${c.educationTier.label})',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildSectionCard(
              title: 'Bureau Reference & Contact',
              icon: Icons.badge_outlined,
              rows: [
                _detailRow('Agent / Reference Name', c.agentReferenceName, isHighlight: true),
                _detailRow('Contact / WhatsApp', c.contactNumber.isNotEmpty ? c.contactNumber : 'N/A'),
              ],
            ),
            const SizedBox(height: 12),

            if (c.notes.isNotEmpty) ...[
              _buildSectionCard(
                title: 'Internal Agent Notes',
                icon: Icons.notes_rounded,
                rows: [
                  _detailRow('Notes', c.notes),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Original Scanned Biodata Preview
            if (c.biodataImagePath != null && File(c.biodataImagePath!).existsSync()) ...[
              const Text(
                'Original Scanned Biodata Document (Local internal storage):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(c.biodataImagePath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF047857)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF047857) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

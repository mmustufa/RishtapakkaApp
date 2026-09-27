import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    setState(() { _candidate = c; _isLoading = false; });
  }

  Future<void> _updateStatus(PipelineStage stage) async {
    if (_candidate == null) return;
    await AppDatabase.instance.updateCandidate(_candidate!.copyWith(pipelineStatus: stage));
    _loadCandidate();
  }

  Future<void> _deleteCandidate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Candidate?'),
        content: Text('Delete "${_candidate?.name}"? This cannot be undone.'),
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

  // ─── Share profile text on WhatsApp ───
  Future<void> _shareOnWhatsApp() async {
    final c = _candidate!;
    final photos = c.allPhotos;
    final photoNote = photos.isNotEmpty
        ? '\n📸 ${photos.length} photo(s) available — ask agent to send separately.'
        : '';
    final text = '💍 *NikkahPakkah — Rishta Profile*\n\n'
        '*Name:* ${c.name}\n'
        '*Gender:* ${c.gender}\n'
        '${c.dob.isNotEmpty ? "*Date of Birth:* ${c.dob}\n" : ""}'
        '*Age:* ${c.age} years\n'
        '*Height:* ${c.heightDisplay}\n'
        '${c.complexion.isNotEmpty ? "*Complexion:* ${c.complexion}\n" : ""}'
        '*Sect:* ${c.sect}\n'
        '*Caste:* ${c.caste}\n'
        '*Education:* ${c.education}\n'
        '${c.occupation.isNotEmpty ? "*Occupation:* ${c.occupation}\n" : ""}'
        '${c.fatherName.isNotEmpty ? "*Father:* ${c.fatherName}\n" : ""}'
        '${c.fatherOccupation.isNotEmpty ? "*Father\'s Occ:* ${c.fatherOccupation}\n" : ""}'
        '${c.motherName.isNotEmpty ? "*Mother:* ${c.motherName}\n" : ""}'
        '${c.city.isNotEmpty ? "*City:* ${c.city}\n" : ""}'
        '${c.address.isNotEmpty ? "*Address:* ${c.address}\n" : ""}'
        '${c.contactNumber.isNotEmpty ? "*Contact:* ${c.contactNumber}\n" : ""}'
        '*Reference:* ${c.agentReferenceName}'
        '$photoNote\n\n'
        '_Shared via NikkahPakkah · Confidential_';

    final encoded = Uri.encodeComponent(text);
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not found on this device.')),
        );
      }
    }
  }

  // ─── Share/view individual photo ───
  Future<void> _sharePhoto(String photoPath) async {
    // On Android: open the image file with the share intent via url_launcher
    final uri = Uri.file(photoPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved at: $photoPath\nForward it manually on WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_candidate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Candidate not found.')),
      );
    }

    final c = _candidate!;
    final isMale = c.isMale;
    final photos = c.allPhotos;
    final hasProfilePhoto = photos.isNotEmpty && File(photos[0]).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('NikkahPakkah'),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditCandidateScreen(candidate: c)),
              );
              if (result == true) _loadCandidate();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _deleteCandidate),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              // WhatsApp Share
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _shareOnWhatsApp,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    foregroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              // Find Matches
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CandidateMatchesScreen(targetCandidate: c)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMale ? const Color(0xFF1E3A8A) : const Color(0xFF9D174D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Find Matches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Profile Header ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMale
                      ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                      : [const Color(0xFF9D174D), const Color(0xFFEC4899)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  // Profile photo (large)
                  Container(
                    width: 90,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                      image: hasProfilePhoto
                          ? DecorationImage(image: FileImage(File(photos[0])), fit: BoxFit.cover)
                          : null,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: !hasProfilePhoto
                        ? Icon(isMale ? Icons.man_rounded : Icons.woman_rounded,
                            size: 54, color: Colors.white.withOpacity(0.9))
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Name & Status
                  Text(
                    c.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(stage: c.pipelineStatus),
                  const SizedBox(height: 10),

                  // DOB + Age + Height — KEY INFO ROW
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _heroStat(Icons.cake_rounded, 'DOB', c.dob.isNotEmpty ? c.dob : '—'),
                        _heroDivider(),
                        _heroStat(Icons.person_rounded, 'Age', '${c.age} yrs'),
                        _heroDivider(),
                        _heroStat(Icons.height_rounded, 'Height', c.heightDisplay),
                        if (c.complexion.isNotEmpty) ...[
                          _heroDivider(),
                          _heroStat(Icons.face_rounded, 'Complexion', c.complexion),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Photos Gallery ──
            if (photos.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF047857)),
                    const SizedBox(width: 6),
                    const Text('Candidate Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Text('${photos.length} photo(s)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) {
                    final p = photos[i];
                    final exists = File(p).existsSync();
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: exists
                              ? Image.file(File(p), width: 90, height: 110, fit: BoxFit.cover)
                              : Container(
                                  width: 90,
                                  height: 110,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                        ),
                        Positioned(
                          bottom: 4, right: 4,
                          child: GestureDetector(
                            onTap: exists ? () => _sharePhoto(p) : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.share_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ── Pipeline ──
                  _buildSection(
                    icon: Icons.timeline_rounded,
                    title: 'Pipeline Stage',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: PipelineStage.values.map((s) {
                        final sel = c.pipelineStatus == s;
                        return ChoiceChip(
                          label: Text(s.displayName, style: const TextStyle(fontSize: 11)),
                          selected: sel,
                          selectedColor: s.color.withOpacity(0.2),
                          onSelected: (val) { if (val) _updateStatus(s); },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Personal ──
                  _buildSection(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Details',
                    child: Column(children: [
                      _row('Gender', c.gender),
                      if (c.dob.isNotEmpty) _row('Date of Birth', c.dob),
                      _row('Age', '${c.age} years'),
                      _row('Height', c.heightDisplay),
                      if (c.complexion.isNotEmpty) _row('Complexion', c.complexion),
                      _row('City', c.city),
                      if (c.address.isNotEmpty) _row('Address', c.address),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── Religion & Community ──
                  _buildSection(
                    icon: Icons.mosque_outlined,
                    title: 'Religion & Community',
                    child: Column(children: [
                      _row('Sect (Maslak)', c.sect, highlight: true),
                      _row('Caste (Biradari)', c.caste, highlight: true),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── Education & Profession ──
                  _buildSection(
                    icon: Icons.school_outlined,
                    title: 'Education & Profession',
                    child: Column(children: [
                      _row('Education', c.education),
                      _row('Education Tier', 'T${c.educationTier.rank}: ${c.educationTier.label}'),
                      if (c.occupation.isNotEmpty) _row('Occupation', c.occupation, highlight: true),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── Family ──
                  if (c.fatherName.isNotEmpty || c.motherName.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.family_restroom_rounded,
                      title: 'Family Background',
                      child: Column(children: [
                        if (c.fatherName.isNotEmpty) _row("Father's Name", c.fatherName),
                        if (c.fatherOccupation.isNotEmpty) _row("Father's Occupation", c.fatherOccupation),
                        if (c.motherName.isNotEmpty) _row("Mother's Name", c.motherName),
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Contact & Agent ──
                  _buildSection(
                    icon: Icons.badge_outlined,
                    title: 'Contact & Reference',
                    child: Column(children: [
                      _row('Agent / Reference', c.agentReferenceName, highlight: true),
                      if (c.contactNumber.isNotEmpty) _row('Phone / WhatsApp', c.contactNumber),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── Notes ──
                  if (c.notes.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.notes_rounded,
                      title: 'Agent Notes',
                      child: Text(c.notes, style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Original Biodata Scan ──
                  if (c.biodataImagePath != null && File(c.biodataImagePath!).existsSync()) ...[
                    _buildSection(
                      icon: Icons.document_scanner_rounded,
                      title: 'Scanned Biodata',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(c.biodataImagePath!),
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _heroDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3));

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF047857)),
            const SizedBox(width: 7),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const Divider(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? const Color(0xFF047857) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

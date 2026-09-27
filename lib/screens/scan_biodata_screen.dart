import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/candidate.dart';
import '../models/education_tier.dart';
import '../models/pipeline_stage.dart';
import '../ocr/biodata_ocr_parser.dart';
import '../ocr/mlkit_scanner_service.dart';
import 'candidate_matches_screen.dart';

class ScanBiodataScreen extends StatefulWidget {
  final File? initialImageFile;

  const ScanBiodataScreen({super.key, this.initialImageFile});

  @override
  State<ScanBiodataScreen> createState() => _ScanBiodataScreenState();
}

class _ScanBiodataScreenState extends State<ScanBiodataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _scanner = MlKitScannerService();

  File? _imageFile;
  String? _savedInternalImagePath;
  bool _isScanning = false;
  String? _rawOcrText;

  // Form Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _educationController = TextEditingController();
  final _sectController = TextEditingController();
  final _casteController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactController = TextEditingController();
  final _agentRefController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Male';
  EducationTier _selectedEducationTier = EducationTier.bachelors;
  PipelineStage _selectedStatus = PipelineStage.pendingReview;

  @override
  void initState() {
    super.initState();
    _agentRefController.text = 'Direct Bureau';
    if (widget.initialImageFile != null) {
      _processImage(widget.initialImageFile!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _educationController.dispose();
    _sectController.dispose();
    _casteController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    _agentRefController.dispose();
    _notesController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      _processImage(File(picked.path));
    }
  }

  Future<void> _processImage(File file) async {
    setState(() {
      _imageFile = file;
      _isScanning = true;
    });

    try {
      final result = await _scanner.scanBiodataImage(file);
      final parsed = result.parsedData;

      setState(() {
        _savedInternalImagePath = result.localImagePath;
        _rawOcrText = parsed.rawText;

        // Auto-fill form fields
        _nameController.text = parsed.name;
        _selectedGender = parsed.gender;
        _ageController.text = parsed.age > 0 ? parsed.age.toString() : '26';

        final feet = (parsed.heightInches / 12).floor();
        final inches = (parsed.heightInches % 12).round();
        _heightFeetController.text = feet.toString();
        _heightInchesController.text = inches.toString();

        _weightController.text = parsed.weightKg > 0 ? parsed.weightKg.toStringAsFixed(0) : '65';
        _educationController.text = parsed.education;
        _selectedEducationTier = parsed.educationTier;
        _sectController.text = parsed.sect;
        _casteController.text = parsed.caste;
        _cityController.text = parsed.city;
        _contactController.text = parsed.contactNumber;
        _agentRefController.text = parsed.agentReferenceName;
        _notesController.text = parsed.notes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biodata scanned successfully! Review fields below.'),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR Scan failed: $e. You can manually enter details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _saveCandidate() async {
    if (!_formKey.currentState!.validate()) return;

    final feet = int.tryParse(_heightFeetController.text) ?? 5;
    final inches = int.tryParse(_heightInchesController.text) ?? 7;
    final totalInches = (feet * 12.0) + inches;
    final heightDisplay = "$feet' $inches\"";

    final candidate = Candidate(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      gender: _selectedGender,
      age: int.tryParse(_ageController.text) ?? 26,
      heightInches: totalInches,
      heightDisplay: heightDisplay,
      weightKg: double.tryParse(_weightController.text) ?? 65.0,
      education: _educationController.text.trim(),
      educationTier: _selectedEducationTier,
      sect: _sectController.text.trim(),
      caste: _casteController.text.trim(),
      city: _cityController.text.trim(),
      contactNumber: _contactController.text.trim(),
      agentReferenceName: _agentRefController.text.trim(),
      biodataImagePath: _savedInternalImagePath,
      pipelineStatus: _selectedStatus,
      notes: _notesController.text.trim(),
    );

    await AppDatabase.instance.insertCandidate(candidate);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Candidate Profile Saved!'),
        content: Text(
          'Candidate "${candidate.name}" has been recorded locally under ${_selectedStatus.displayName}. Would you like to find matching candidates right now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Return to dashboard
            },
            child: const Text('Back to Dashboard'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CandidateMatchesScreen(targetCandidate: candidate),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Find Matches'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Verify Biodata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Profile',
            onPressed: _saveCandidate,
          ),
        ],
      ),
      body: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF047857)),
                  SizedBox(height: 16),
                  Text(
                    'Extracting text with on-device ML Kit OCR...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top: Image Upload Action Cards
                    _buildImagePickerHeader(),
                    const SizedBox(height: 16),

                    // Manual Override Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-scanned fields are displayed below. You can manually edit or override any field before saving.',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form Fields
                    _buildGenderSelector(),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Candidate Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age *',
                              prefixIcon: Icon(Icons.cake_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _heightFeetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ft *',
                              prefixIcon: Icon(Icons.height_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _heightInchesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Inches *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sect (Maslak) & Caste (Biradari)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sectController,
                            decoration: const InputDecoration(
                              labelText: 'Sect (Maslak) *',
                              hintText: 'e.g. Tablighi / Ahle Hadith / Barelvi',
                              prefixIcon: Icon(Icons.mosque_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Sect is required for matching'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _casteController,
                            decoration: const InputDecoration(
                              labelText: 'Caste (Biradari) *',
                              hintText: 'e.g. Sheikh / Syed / Rajput',
                              prefixIcon: Icon(Icons.family_restroom_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Caste is required for matching'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildQuickSectChips(),
                    const SizedBox(height: 12),

                    // Education & Tier
                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Education Degree / Major *',
                        hintText: 'e.g. BS Computer Science, MBBS, MBA',
                        prefixIcon: Icon(Icons.school_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Education is required'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<EducationTier>(
                      value: _selectedEducationTier,
                      decoration: const InputDecoration(
                        labelText: 'Education Hierarchy Tier *',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                        border: OutlineInputBorder(),
                        helperText: 'Used for strict Male >= Female hierarchy rule',
                      ),
                      items: EducationTier.values.map((tier) {
                        return DropdownMenuItem(
                          value: tier,
                          child: Text(
                            'Tier ${tier.rank}: ${tier.label}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedEducationTier = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // City & Contact
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              prefixIcon: Icon(Icons.location_city_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone / WhatsApp',
                              prefixIcon: Icon(Icons.phone_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Agent Name / Reference Name (Mandatory requirement!)
                    TextFormField(
                      controller: _agentRefController,
                      decoration: const InputDecoration(
                        labelText: 'Agent Name / Reference Name *',
                        hintText: 'Name of agent or source who submitted this biodata',
                        prefixIcon: Icon(Icons.badge_rounded),
                        border: OutlineInputBorder(),
                        helperText: 'Mandatory: tracks bureau source for multi-agent networking',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Agent/Reference name is mandatory'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Pipeline Stage Selector
                    DropdownButtonFormField<PipelineStage>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Initial Pipeline Status',
                        prefixIcon: Icon(Icons.timeline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: PipelineStage.values.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Row(
                            children: [
                              Icon(stage.icon, size: 16, color: stage.color),
                              const SizedBox(width: 8),
                              Text(stage.displayName),
                            ],
                          ),
                        );
                      }).toList>,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Agent Internal Notes / Requirements',
                        hintText: 'Special family expectations, house ownership, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _saveCandidate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save Profile & Run Matchmaker',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePickerHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _imageFile!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Take Photo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Pick Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        const Text(
          'Gender: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Male (Groom)'),
          selected: _selectedGender == 'Male',
          selectedColor: Colors.blue.shade100,
          onSelected: (val) {
            if (val) setState(() => _selectedGender = 'Male');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Female (Bride)'),
          selected: _selectedGender == 'Female',
          selectedColor: Colors.pink.shade100,
          onSelected: (val) {
            if (val) setState(() => _selectedGender = 'Female');
          },
        ),
      ],
    );
  }

  Widget _buildQuickSectChips() {
    return Wrap(
      spacing: 6,
      children: [
        'Tablighi',
        'Ahle Hadith',
        'Barelvi',
        'Deobandi',
        'Sunni',
        'Shia',
      ].map((sect) {
        return ActionChip(
          label: Text(sect, style: const TextStyle(fontSize: 11)),
          onPressed: () {
            setState(() {
              _sectController.text = sect;
            });
          },
        );
      }).toList(),
    );
  }
}

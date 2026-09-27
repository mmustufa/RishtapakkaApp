import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  File? _imageFile; // Biodata scan image
  String? _savedInternalImagePath;
  bool _isScanning = false;
  String? _rawOcrText;

  // Up to 3 candidate photos
  final List<File?> _candidatePhotos = [null, null, null];

  // Form Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _complexionController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _sectController = TextEditingController();
  final _casteController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherOccController = TextEditingController();
  final _motherNameController = TextEditingController();
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
    _dobController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _complexionController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _sectController.dispose();
    _casteController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _fatherNameController.dispose();
    _fatherOccController.dispose();
    _motherNameController.dispose();
    _agentRefController.dispose();
    _notesController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  // Pick biodata scan image
  Future<void> _pickBiodataImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) _processImage(File(picked.path));
  }

  // Pick a candidate photo (slot index 0,1,2)
  Future<void> _pickCandidatePhoto(int slot) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _candidatePhotos[slot] = File(picked.path));
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

        // Auto-fill all form fields from improved OCR
        _nameController.text = parsed.name;
        _selectedGender = parsed.gender.isNotEmpty ? parsed.gender : 'Male';
        _dobController.text = parsed.dob;
        _ageController.text = parsed.age > 0 ? parsed.age.toString() : '26';

        final ft = (parsed.heightInches / 12).floor();
        final inch = (parsed.heightInches % 12).round();
        _heightFeetController.text = ft.toString();
        _heightInchesController.text = inch.toString();

        _complexionController.text = parsed.complexion;
        _educationController.text = parsed.education;
        _selectedEducationTier = parsed.educationTier;
        _occupationController.text = parsed.occupation;
        _sectController.text = parsed.sect;
        _casteController.text = parsed.caste;
        _cityController.text = parsed.city;
        _addressController.text = parsed.address;
        _contactController.text = parsed.contactNumber;
        _fatherNameController.text = parsed.fatherName;
        _fatherOccController.text = parsed.fatherOccupation;
        _motherNameController.text = parsed.motherName;
        _agentRefController.text = parsed.agentReferenceName;
        _notesController.text = parsed.notes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Biodata scanned! Review all fields below before saving.'),
          backgroundColor: Color(0xFF047857),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('OCR Scan failed: $e — Enter details manually.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Save a photo to internal app storage and return its path
  Future<String?> _savePhotoToInternal(File photo, String suffix) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, 'photos', '${const Uuid().v4()}_$suffix.jpg');
      await Directory(p.dirname(dest)).create(recursive: true);
      await photo.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCandidate() async {
    if (!_formKey.currentState!.validate()) return;

    final ft = int.tryParse(_heightFeetController.text) ?? 5;
    final inch = int.tryParse(_heightInchesController.text) ?? 7;
    final totalInches = (ft * 12.0) + inch;
    final heightDisplay = "$ft' $inch\"";

    // Save candidate photos to internal storage
    final photoPath = _candidatePhotos[0] != null
        ? await _savePhotoToInternal(_candidatePhotos[0]!, 'photo1') : null;
    final photo2Path = _candidatePhotos[1] != null
        ? await _savePhotoToInternal(_candidatePhotos[1]!, 'photo2') : null;
    final photo3Path = _candidatePhotos[2] != null
        ? await _savePhotoToInternal(_candidatePhotos[2]!, 'photo3') : null;

    final candidate = Candidate(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      gender: _selectedGender,
      dob: _dobController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 26,
      heightInches: totalInches,
      heightDisplay: heightDisplay,
      complexion: _complexionController.text.trim(),
      education: _educationController.text.trim(),
      educationTier: _selectedEducationTier,
      occupation: _occupationController.text.trim(),
      sect: _sectController.text.trim(),
      caste: _casteController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      contactNumber: _contactController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      fatherOccupation: _fatherOccController.text.trim(),
      motherName: _motherNameController.text.trim(),
      agentReferenceName: _agentRefController.text.trim(),
      photoPath: photoPath,
      photo2Path: photo2Path,
      photo3Path: photo3Path,
      biodataImagePath: _savedInternalImagePath,
      pipelineStatus: _selectedStatus,
      notes: _notesController.text.trim(),
    );

    await AppDatabase.instance.insertCandidate(candidate);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Profile Saved!'),
        content: Text('"${candidate.name}" has been saved locally. Find matches now?'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context, true); },
            child: const Text('Back to Dashboard'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CandidateMatchesScreen(targetCandidate: candidate)),
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
        title: const Text('Scan & Save Biodata'),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
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
                  Text('Scanning biodata with ML Kit OCR...', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── STEP 1: Biodata Scan Image ──
                    _buildSectionHeader('📄 Step 1: Upload Biodata Sheet'),
                    const SizedBox(height: 8),
                    _buildBiodataImagePicker(),
                    const SizedBox(height: 16),

                    // ── STEP 2: Candidate Photos ──
                    _buildSectionHeader('📸 Step 2: Candidate Photos (1–3)'),
                    const SizedBox(height: 4),
                    const Text(
                      'First photo is your profile picture. Up to 3 can be shared on WhatsApp.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildPhotoSlots(),
                    const SizedBox(height: 16),

                    // ── OCR Notice ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(children: [
                        Icon(Icons.edit_note_rounded, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Step 3: Verify all auto-scanned fields below and correct any errors before saving.',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── PERSONAL DETAILS ──
                    _buildSectionHeader('👤 Personal Details'),
                    const SizedBox(height: 10),
                    _buildGenderSelector(),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 10),

                    Row(children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _dobController,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'e.g. 06 March 1997',
                            prefixIcon: Icon(Icons.cake_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _heightFeetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Height (ft) *',
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
                          controller: _complexionController,
                          decoration: const InputDecoration(
                            labelText: 'Complexion',
                            hintText: 'Fair / Dusky',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    // Sect & Caste
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sectController,
                          decoration: const InputDecoration(
                            labelText: 'Sect (Maslak) *',
                            hintText: 'Sunni / Barelvi / Deobandi',
                            prefixIcon: Icon(Icons.mosque_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _casteController,
                          decoration: const InputDecoration(
                            labelText: 'Caste (Biradari) *',
                            hintText: 'Sheikh / Syed / Rajput',
                            prefixIcon: Icon(Icons.family_restroom_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    _buildQuickSectChips(),
                    const SizedBox(height: 12),

                    // ── EDUCATION & PROFESSION ──
                    _buildSectionHeader('🎓 Education & Profession'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Qualification / Education *',
                        hintText: 'e.g. Diploma in Civil Engineering, BE CSE',
                        prefixIcon: Icon(Icons.school_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<EducationTier>(
                      value: _selectedEducationTier,
                      decoration: const InputDecoration(
                        labelText: 'Education Tier *',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                        border: OutlineInputBorder(),
                        helperText: 'Used for Groom >= Bride hierarchy rule',
                      ),
                      items: EducationTier.values.map((tier) => DropdownMenuItem(
                        value: tier,
                        child: Text('T${tier.rank}: ${tier.label}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) { if (val != null) setState(() => _selectedEducationTier = val); },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation / Profession',
                        hintText: 'e.g. Businessman, Engineer at TCS, Revenue Assistant',
                        prefixIcon: Icon(Icons.work_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── CONTACT & LOCATION ──
                    _buildSectionHeader('📍 Location & Contact'),
                    const SizedBox(height: 10),

                    Row(children: [
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
                      const SizedBox(width: 10),
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
                    ]),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Residential Address',
                        prefixIcon: Icon(Icons.home_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── FAMILY BACKGROUND ──
                    _buildSectionHeader('👨‍👩‍👧 Family Background'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _fatherNameController,
                      decoration: const InputDecoration(
                        labelText: "Father's Name",
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _fatherOccController,
                      decoration: const InputDecoration(
                        labelText: "Father's Occupation",
                        prefixIcon: Icon(Icons.business_center_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _motherNameController,
                      decoration: const InputDecoration(
                        labelText: "Mother's Name",
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── AGENT & PIPELINE ──
                    _buildSectionHeader('📋 Agent & Pipeline'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _agentRefController,
                      decoration: const InputDecoration(
                        labelText: 'Agent / Reference Name *',
                        hintText: 'Name of agent or bureau who submitted this biodata',
                        prefixIcon: Icon(Icons.badge_rounded),
                        border: OutlineInputBorder(),
                        helperText: 'Mandatory: tracks bureau source for networking',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Agent/Reference name is mandatory' : null,
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<PipelineStage>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Initial Pipeline Status',
                        prefixIcon: Icon(Icons.timeline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: PipelineStage.values.map((stage) => DropdownMenuItem(
                        value: stage,
                        child: Row(children: [
                          Icon(stage.icon, size: 16, color: stage.color),
                          const SizedBox(width: 8),
                          Text(stage.displayName),
                        ]),
                      )).toList(),
                      onChanged: (val) { if (val != null) setState(() => _selectedStatus = val); },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Agent Notes / Requirements',
                        hintText: 'Special expectations, house ownership, etc.',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Profile & Run Matchmaker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF047857),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBiodataImagePicker() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_imageFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ] else
            Container(
              height: 80,
              alignment: Alignment.center,
              child: const Text('📄 Upload a paper biodata photo to auto-extract fields',
                  style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickBiodataImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Camera', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickBiodataImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label: const Text('Gallery', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlots() {
    return Row(
      children: List.generate(3, (i) {
        final photo = _candidatePhotos[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () => _pickCandidatePhoto(i),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: photo != null ? const Color(0xFF047857) : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade50,
                ),
                child: photo != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(photo, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _candidatePhotos[i] = null),
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(i == 0 ? Icons.person_add_rounded : Icons.add_photo_alternate_rounded,
                              color: Colors.grey.shade400, size: 26),
                          const SizedBox(height: 4),
                          Text('Photo ${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGenderSelector() {
    return Row(children: [
      const Text('Gender:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(width: 12),
      ChoiceChip(
        label: const Text('Male (Groom)'),
        selected: _selectedGender == 'Male',
        selectedColor: Colors.blue.shade100,
        onSelected: (val) { if (val) setState(() => _selectedGender = 'Male'); },
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text('Female (Bride)'),
        selected: _selectedGender == 'Female',
        selectedColor: Colors.pink.shade100,
        onSelected: (val) { if (val) setState(() => _selectedGender = 'Female'); },
      ),
    ]);
  }

  Widget _buildQuickSectChips() {
    return Wrap(
      spacing: 6,
      children: ['Sunni', 'Barelvi', 'Deobandi', 'Ahle Hadith', 'Tablighi', 'Shia'].map((s) {
        return ActionChip(
          label: Text(s, style: const TextStyle(fontSize: 11)),
          onPressed: () => setState(() => _sectController.text = s),
        );
      }).toList(),
    );
  }
}

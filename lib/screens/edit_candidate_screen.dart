import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/candidate.dart';
import '../models/education_tier.dart';
import '../models/pipeline_stage.dart';

class EditCandidateScreen extends StatefulWidget {
  final Candidate candidate;

  const EditCandidateScreen({super.key, required this.candidate});

  @override
  State<EditCandidateScreen> createState() => _EditCandidateScreenState();
}

class _EditCandidateScreenState extends State<EditCandidateScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _ageController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _weightController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;
  late TextEditingController _fatherNameController;
  late TextEditingController _fatherOccController;
  late TextEditingController _motherNameController;
  late TextEditingController _sectController;
  late TextEditingController _casteController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _agentRefController;
  late TextEditingController _notesController;

  late String _gender;
  late EducationTier _educationTier;
  late PipelineStage _pipelineStatus;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    _nameController = TextEditingController(text: c.name);
    _dobController = TextEditingController(text: c.dob);
    _ageController = TextEditingController(text: c.age.toString());

    final feet = (c.heightInches / 12).floor();
    final inches = (c.heightInches % 12).round();
    _heightFeetController = TextEditingController(text: feet.toString());
    _heightInchesController = TextEditingController(text: inches.toString());

    _weightController = TextEditingController(text: c.weightKg.toStringAsFixed(0));
    _educationController = TextEditingController(text: c.education);
    _occupationController = TextEditingController(text: c.occupation);
    _fatherNameController = TextEditingController(text: c.fatherName);
    _fatherOccController = TextEditingController(text: c.fatherOccupation);
    _motherNameController = TextEditingController(text: c.motherName);
    _sectController = TextEditingController(text: c.sect);
    _casteController = TextEditingController(text: c.caste);
    _cityController = TextEditingController(text: c.city);
    _addressController = TextEditingController(text: c.address);
    _contactController = TextEditingController(text: c.contactNumber);
    _agentRefController = TextEditingController(text: c.agentReferenceName);
    _notesController = TextEditingController(text: c.notes);

    _gender = c.gender;
    _educationTier = c.educationTier;
    _pipelineStatus = c.pipelineStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _fatherNameController.dispose();
    _fatherOccController.dispose();
    _motherNameController.dispose();
    _sectController.dispose();
    _casteController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _agentRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final feet = int.tryParse(_heightFeetController.text) ?? 5;
    final inches = int.tryParse(_heightInchesController.text) ?? 7;
    final totalInches = (feet * 12.0) + inches;

    final updated = widget.candidate.copyWith(
      name: _nameController.text.trim(),
      gender: _gender,
      dob: _dobController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 25,
      heightInches: totalInches,
      heightDisplay: "$feet' $inches\"",
      weightKg: double.tryParse(_weightController.text) ?? 65.0,
      education: _educationController.text.trim(),
      educationTier: _educationTier,
      occupation: _occupationController.text.trim(),
      fatherName: _fatherNameController.text.trim(),
      fatherOccupation: _fatherOccController.text.trim(),
      motherName: _motherNameController.text.trim(),
      sect: _sectController.text.trim(),
      caste: _casteController.text.trim(),
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      contactNumber: _contactController.text.trim(),
      agentReferenceName: _agentRefController.text.trim(),
      pipelineStatus: _pipelineStatus,
      notes: _notesController.text.trim(),
    );

    await AppDatabase.instance.updateCandidate(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidate profile updated successfully.'),
          backgroundColor: Color(0xFF047857),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Candidate Details'),
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Candidate Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (DOB)',
                        hintText: 'e.g. 01-01-1999',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age (Years) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (Feet)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (Inches)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sectController,
                      decoration: const InputDecoration(
                        labelText: 'Sect (Maslak)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _casteController,
                      decoration: const InputDecoration(
                        labelText: 'Caste (Biradari)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Education Degree *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Candidate Occupation',
                        hintText: 'e.g. Civil Engineer, Teacher',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EducationTier>(
                value: _educationTier,
                decoration: const InputDecoration(
                  labelText: 'Education Tier (Hierarchy)',
                  border: OutlineInputBorder(),
                ),
                items: EducationTier.values.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text('Tier ${tier.rank}: ${tier.label}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _educationTier = val);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Family Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF047857)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fatherNameController,
                      decoration: const InputDecoration(
                        labelText: "Father's Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatherOccController,
                      decoration: const InputDecoration(
                        labelText: "Father's Occupation",
                        hintText: 'e.g. Project Engineer, Business',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                  labelText: "Mother's Name / Details",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact & Reference',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF047857)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _agentRefController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name / Reference Name *',
                  border: OutlineInputBorder(),
                  helperText: 'Mandatory field',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Agent Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Update Candidate Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

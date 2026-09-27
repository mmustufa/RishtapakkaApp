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
  late TextEditingController _ageController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _weightController;
  late TextEditingController _educationController;
  late TextEditingController _sectController;
  late TextEditingController _casteController;
  late TextEditingController _cityController;
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
    _ageController = TextEditingController(text: c.age.toString());

    final feet = (c.heightInches / 12).floor();
    final inches = (c.heightInches % 12).round();
    _heightFeetController = TextEditingController(text: feet.toString());
    _heightInchesController = TextEditingController(text: inches.toString());

    _weightController = TextEditingController(text: c.weightKg.toStringAsFixed(0));
    _educationController = TextEditingController(text: c.education);
    _sectController = TextEditingController(text: c.sect);
    _casteController = TextEditingController(text: c.caste);
    _cityController = TextEditingController(text: c.city);
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
      age: int.tryParse(_ageController.text) ?? 25,
      heightInches: totalInches,
      heightDisplay: "$feet' $inches\"",
      weightKg: double.tryParse(_weightController.text) ?? 65.0,
      education: _educationController.text.trim(),
      educationTier: _educationTier,
      sect: _sectController.text.trim(),
      caste: _casteController.text.trim(),
      city: _cityController.text.trim(),
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Candidate Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ft *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Inches *',
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
                        labelText: 'Sect (Maslak) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _casteController,
                      decoration: const InputDecoration(
                        labelText: 'Caste (Biradari) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education Degree *',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 12),
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

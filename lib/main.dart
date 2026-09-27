import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'models/candidate.dart';
import 'models/education_tier.dart';
import 'models/pipeline_stage.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database and seed initial test candidates if empty
  await _seedDemoCandidatesIfEmpty();

  runApp(const NikahBureauApp());
}

Future<void> _seedDemoCandidatesIfEmpty() async {
  final candidates = await AppDatabase.instance.getAllCandidates();
  if (candidates.isEmpty) {
    // Seed 4 sample candidates to test matching rules immediately:
    // Groom 1: Tariq Sheikh (Barelvi, Sheikh, 5'11", Masters, 28)
    // Bride 1: Fatima Sheikh (Barelvi, Sheikh, 5'5", Bachelors, 25) -> 100% MATCH!
    // Bride 2: Ayesha Syed (Deobandi, Syed, 5'4", Masters, 24) -> FAILS (Sect & Caste mismatch)
    // Groom 2: Bilal Ansari (Tablighi, Ansari, 5'6", Intermediate, 29)
    await AppDatabase.instance.insertCandidate(
      Candidate(
        id: 'seed-groom-1',
        name: 'Tariq Sheikh',
        gender: 'Male',
        age: 28,
        heightInches: 71.0, // 5' 11"
        heightDisplay: "5' 11\"",
        weightKg: 74.0,
        education: 'MS Computer Science',
        educationTier: EducationTier.masters,
        sect: 'Barelvi',
        caste: 'Sheikh',
        city: 'Lahore',
        contactNumber: '+92 300 1234567',
        agentReferenceName: 'Haji Aslam Bureau',
        pipelineStatus: PipelineStage.pendingReview,
        notes: 'Senior Software Architect. Own house in DHA Lahore.',
      ),
    );

    await AppDatabase.instance.insertCandidate(
      Candidate(
        id: 'seed-bride-1',
        name: 'Fatima Sheikh',
        gender: 'Female',
        age: 25,
        heightInches: 65.0, // 5' 5"
        heightDisplay: "5' 5\"",
        weightKg: 58.0,
        education: 'BSc Clinical Psychology',
        educationTier: EducationTier.bachelors,
        sect: 'Barelvi',
        caste: 'Sheikh',
        city: 'Lahore',
        contactNumber: '+92 321 9876543',
        agentReferenceName: 'Direct Family Reference',
        pipelineStatus: PipelineStage.pendingReview,
        notes: 'Religious, family-oriented. Looking for cultured Sheikh family.',
      ),
    );

    await AppDatabase.instance.insertCandidate(
      Candidate(
        id: 'seed-bride-2',
        name: 'Ayesha Syed',
        gender: 'Female',
        age: 24,
        heightInches: 64.0, // 5' 4"
        heightDisplay: "5' 4\"",
        weightKg: 54.0,
        education: 'M.Com Finance',
        educationTier: EducationTier.masters,
        sect: 'Deobandi',
        caste: 'Syed',
        city: 'Karachi',
        contactNumber: '+92 333 4567890',
        agentReferenceName: 'Al-Madina Rishta Centre',
        pipelineStatus: PipelineStage.pendingReview,
        notes: 'Strict Syed family seeking practicing Deobandi gentleman.',
      ),
    );

    await AppDatabase.instance.insertCandidate(
      Candidate(
        id: 'seed-groom-2',
        name: 'Bilal Ansari',
        gender: 'Male',
        age: 29,
        heightInches: 66.0, // 5' 6"
        heightDisplay: "5' 6\"",
        weightKg: 68.0,
        education: 'F.Sc Pre-Engineering',
        educationTier: EducationTier.intermediate,
        sect: 'Tablighi',
        caste: 'Ansari',
        city: 'Rawalpindi',
        contactNumber: '+92 345 1122334',
        agentReferenceName: 'Maulana Farooq Bureau',
        pipelineStatus: PipelineStage.pendingReview,
        notes: 'Textile wholesale business owner. Active in Tabligh.',
      ),
    );
  }
}

class NikahBureauApp extends StatelessWidget {
  const NikahBureauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NikahBureau Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857), // Islamic Emerald Green
          primary: const Color(0xFF047857),
          secondary: const Color(0xFF1E3A8A), // Royal Blue
          surface: const Color(0xFFF9FAFB),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF047857),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

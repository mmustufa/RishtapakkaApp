import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/candidate.dart';
import '../models/pipeline_stage.dart';
import '../models/proposal.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rishta_local_bureau.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Candidates Table
    await db.execute('''
      CREATE TABLE candidates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_inches REAL NOT NULL,
        height_display TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        education TEXT NOT NULL,
        education_tier INTEGER NOT NULL,
        sect TEXT NOT NULL,
        caste TEXT NOT NULL,
        city TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        agent_reference_name TEXT NOT NULL,
        photo_path TEXT,
        biodata_image_path TEXT,
        pipeline_status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index for high-performance matching queries
    await db.execute(
      'CREATE INDEX idx_candidates_gender_sect_caste ON candidates(gender, sect, caste)',
    );

    // 2. Proposals Table (Links candidate pairs)
    await db.execute('''
      CREATE TABLE proposals (
        id TEXT PRIMARY KEY,
        male_candidate_id TEXT NOT NULL,
        female_candidate_id TEXT NOT NULL,
        male_name TEXT NOT NULL,
        female_name TEXT NOT NULL,
        sect TEXT NOT NULL,
        caste TEXT NOT NULL,
        stage TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (male_candidate_id) REFERENCES candidates (id) ON DELETE CASCADE,
        FOREIGN KEY (female_candidate_id) REFERENCES candidates (id) ON DELETE CASCADE
      )
    ''');

    // 3. Status Timeline History (Audit Trail)
    await db.execute('''
      CREATE TABLE status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proposal_id TEXT NOT NULL,
        previous_stage TEXT,
        new_stage TEXT NOT NULL,
        note TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (proposal_id) REFERENCES proposals (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CANDIDATE CRUD ---

  Future<int> insertCandidate(Candidate candidate) async {
    final db = await instance.database;
    return await db.insert(
      'candidates',
      candidate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCandidate(Candidate candidate) async {
    final db = await instance.database;
    return await db.update(
      'candidates',
      candidate.toMap(),
      where: 'id = ?',
      whereArgs: [candidate.id],
    );
  }

  Future<int> deleteCandidate(String id) async {
    final db = await instance.database;
    return await db.delete(
      'candidates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Candidate?> getCandidateById(String id) async {
    final db = await instance.database;
    final results = await db.query(
      'candidates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Candidate.fromMap(results.first);
    }
    return null;
  }

  Future<List<Candidate>> getAllCandidates({
    String? gender,
    String? sect,
    String? caste,
    PipelineStage? status,
    String? searchQuery,
  }) async {
    final db = await instance.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (gender != null && gender.isNotEmpty) {
      whereClauses.add('LOWER(gender) = ?');
      whereArgs.add(gender.toLowerCase());
    }

    if (sect != null && sect.isNotEmpty) {
      whereClauses.add('LOWER(sect) = ?');
      whereArgs.add(sect.toLowerCase());
    }

    if (caste != null && caste.isNotEmpty) {
      whereClauses.add('LOWER(caste) = ?');
      whereArgs.add(caste.toLowerCase());
    }

    if (status != null) {
      whereClauses.add('pipeline_status = ?');
      whereArgs.add(status.key);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add(
        '(LOWER(name) LIKE ? OR LOWER(city) LIKE ? OR LOWER(caste) LIKE ? OR LOWER(sect) LIKE ? OR LOWER(agent_reference_name) LIKE ?)',
      );
      whereArgs.addAll([q, q, q, q, q]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'candidates',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
    );

    return results.map((row) => Candidate.fromMap(row)).toList();
  }

  // --- PROPOSALS & PIPELINE ---

  Future<int> insertProposal(Proposal proposal) async {
    final db = await instance.database;
    final res = await db.insert(
      'proposals',
      proposal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Record initial stage in history
    await db.insert('status_history', {
      'proposal_id': proposal.id,
      'previous_stage': null,
      'new_stage': proposal.stage.key,
      'note': proposal.notes.isNotEmpty ? proposal.notes : 'Proposal initiated',
      'timestamp': DateTime.now().toIso8601String(),
    });

    return res;
  }

  Future<int> updateProposalStage(
    String proposalId,
    PipelineStage newStage, {
    String note = '',
  }) async {
    final db = await instance.database;
    final existing = await db.query(
      'proposals',
      columns: ['stage'],
      where: 'id = ?',
      whereArgs: [proposalId],
      limit: 1,
    );

    final prevStage = existing.isNotEmpty ? existing.first['stage'] as String? : null;

    final updated = await db.update(
      'proposals',
      {
        'stage': newStage.key,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    await db.insert('status_history', {
      'proposal_id': proposalId,
      'previous_stage': prevStage,
      'new_stage': newStage.key,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return updated;
  }

  Future<List<Proposal>> getProposals({PipelineStage? stage}) async {
    final db = await instance.database;
    final where = stage != null ? 'stage = ?' : null;
    final whereArgs = stage != null ? [stage.key] : null;

    final results = await db.query(
      'proposals',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return results.map((e) => Proposal.fromMap(e)).toList();
  }

  Future<Map<String, int>> getBureauDashboardStats() async {
    final db = await instance.database;
    final totalCand = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM candidates'),
        ) ??
        0;
    final totalMales = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM candidates WHERE LOWER(gender) = 'male'"),
        ) ??
        0;
    final totalFemales = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM candidates WHERE LOWER(gender) = 'female'"),
        ) ??
        0;
    final activeProposals = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM proposals WHERE stage NOT IN ('closed')",
          ),
        ) ??
        0;
    final shortlisted = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM proposals WHERE stage = 'shortlisted'",
          ),
        ) ??
        0;

    return {
      'totalCandidates': totalCand,
      'males': totalMales,
      'females': totalFemales,
      'activeProposals': activeProposals,
      'shortlisted': shortlisted,
    };
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

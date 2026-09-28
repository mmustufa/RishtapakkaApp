import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/app_database.dart';
import '../models/candidate.dart';
import '../models/pipeline_stage.dart';
import '../utils/share_helper.dart';
import '../widgets/candidate_card.dart';
import 'candidate_matches_screen.dart';
import 'pipeline_tracker_screen.dart';
import 'profile_detail_screen.dart';
import 'scan_biodata_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  Map<String, int> _stats = {
    'totalCandidates': 0,
    'males': 0,
    'females': 0,
    'activeProposals': 0,
    'shortlisted': 0,
  };
  List<Candidate> _candidates = [];
  bool _isLoading = true;

  String? _genderFilter;
  PipelineStage? _statusFilter;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final stats = await AppDatabase.instance.getBureauDashboardStats();
    final candidates = await AppDatabase.instance.getAllCandidates(
      gender: _genderFilter,
      status: _statusFilter,
      searchQuery: _searchController.text,
    );

    setState(() {
      _stats = stats;
      _candidates = candidates;
      _isLoading = false;
    });
  }

  Future<void> _shareOnWhatsApp(Candidate candidate) async {
    await ShareHelper.shareCandidateWithPhotos(context, candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NikkahPakkah',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '100% Offline Muslim Marriage Bureau System',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded),
            tooltip: 'Proposal Pipeline',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PipelineTrackerScreen()),
              ).then((_) => _refreshData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Biodata (OCR)'),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanBiodataScreen()),
          );
          if (res == true) _refreshData();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Top Bureau Statistics Dashboard
            SliverToBoxAdapter(
              child: _buildMetricsHeader(),
            ),

            // Search Bar & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, caste, sect, city, agent...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _refreshData();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => _refreshData(),
                    ),
                    const SizedBox(height: 8),
                    _buildFilterChips(),
                  ],
                ),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Candidate Profiles (${_candidates.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanBiodataScreen(),
                          ),
                        ).then((_) => _refreshData());
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Profile'),
                    ),
                  ],
                ),
              ),
            ),

            // Candidate Cards List
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _candidates.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No candidates found in local database.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap "Scan Biodata (OCR)" to photograph and auto-import candidate sheets.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final candidate = _candidates[index];
                            return CandidateCard(
                              candidate: candidate,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileDetailScreen(
                                      candidateId: candidate.id,
                                    ),
                                  ),
                                ).then((_) => _refreshData());
                              },
                              onShare: () => _shareOnWhatsApp(candidate),
                              onFindMatches: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CandidateMatchesScreen(
                                      targetCandidate: candidate,
                                    ),
                                  ),
                                ).then((_) => _refreshData());
                              },
                            );
                          },
                          childCount: _candidates.length,
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marriage Bureau Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white70),
                  SizedBox(width: 4),
                  Text('100% Offline', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricColumn('Candidates', '${_stats['totalCandidates']}'),
              _metricColumn('Grooms (M)', '${_stats['males']}'),
              _metricColumn('Brides (F)', '${_stats['females']}'),
              _metricColumn('Active Proposals', '${_stats['activeProposals']}'),
              _metricColumn('Accepted', '${_stats['shortlisted']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String title, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Profiles'),
            selected: _genderFilter == null && _statusFilter == null,
            onSelected: (_) {
              setState(() {
                _genderFilter = null;
                _statusFilter = null;
              });
              _refreshData();
            },
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Grooms (Male)'),
            selected: _genderFilter == 'Male',
            selectedColor: Colors.blue.shade100,
            onSelected: (val) {
              setState(() => _genderFilter = val ? 'Male' : null);
              _refreshData();
            },
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Brides (Female)'),
            selected: _genderFilter == 'Female',
            selectedColor: Colors.pink.shade100,
            onSelected: (val) {
              setState(() => _genderFilter = val ? 'Female' : null);
              _refreshData();
            },
          ),
          const SizedBox(width: 6),
          ...PipelineStage.values.map((stage) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(stage.displayName),
                selected: _statusFilter == stage,
                selectedColor: stage.color.withOpacity(0.2),
                onSelected: (val) {
                  setState(() => _statusFilter = val ? stage : null);
                  _refreshData();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

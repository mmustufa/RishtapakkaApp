import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/pipeline_stage.dart';
import '../models/proposal.dart';
import '../widgets/status_badge.dart';

class PipelineTrackerScreen extends StatefulWidget {
  const PipelineTrackerScreen({super.key});

  @override
  State<PipelineTrackerScreen> createState() => _PipelineTrackerScreenState();
}

class _PipelineTrackerScreenState extends State<PipelineTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Proposal> _allProposals = [];

  final List<PipelineStage> _stages = [
    PipelineStage.pendingReview,
    PipelineStage.proposalSent,
    PipelineStage.familyDiscussion,
    PipelineStage.shortlisted,
    PipelineStage.closed,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    _loadProposals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProposals() async {
    setState(() => _isLoading = true);
    final list = await AppDatabase.instance.getProposals();
    setState(() {
      _allProposals = list;
      _isLoading = false;
    });
  }

  Future<void> _showStageChangeDialog(Proposal proposal) async {
    final noteController = TextEditingController();
    PipelineStage selectedNextStage = proposal.stage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Proposal Stage'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${proposal.maleName} & ${proposal.femaleName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('New Pipeline Stage:', style: TextStyle(fontSize: 12)),
                DropdownButton<PipelineStage>(
                  isExpanded: true,
                  value: selectedNextStage,
                  items: _stages.map((stage) {
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
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedNextStage = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Agent Meeting / Feedback Notes',
                    hintText: 'e.g. Boy visited girl house; discussion positive.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppDatabase.instance.updateProposalStage(
                    proposal.id,
                    selectedNextStage,
                    note: noteController.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _loadProposals();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Pipeline Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: _stages.map((stage) {
            final count = _allProposals.where((p) => p.stage == stage).length;
            return Tab(
              child: Row(
                children: [
                  Icon(stage.icon, size: 16),
                  const SizedBox(width: 6),
                  Text('${stage.displayName} ($count)'),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _stages.map((stage) {
                final stageProposals =
                    _allProposals.where((p) => p.stage == stage).toList();
                return _buildStageProposalList(stage, stageProposals);
              }).toList(),
            ),
    );
  }

  Widget _buildStageProposalList(PipelineStage stage, List<Proposal> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stage.icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No proposals currently in "${stage.displayName}"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: stage.color.withOpacity(0.4), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Male & Female names + Badge
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.man, size: 18, color: Colors.blue),
                              Text(
                                p.maleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('🤝', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              const Icon(Icons.woman, size: 18, color: Colors.pink),
                              Text(
                                p.femaleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sect: ${p.sect} • Caste: ${p.caste}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(stage: p.stage, isCompact: true),
                  ],
                ),

                if (p.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.notes,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],

                const Divider(height: 16),

                // Footer: Date updated & Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Updated: ${dateFormat.format(p.updatedAt.toLocal())}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showStageChangeDialog(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stage.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Update Stage', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

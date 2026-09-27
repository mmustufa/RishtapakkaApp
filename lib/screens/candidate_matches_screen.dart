import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../matching/matching_engine.dart';
import '../models/candidate.dart';
import '../models/pipeline_stage.dart';
import '../models/proposal.dart';
import '../widgets/match_score_card.dart';
import 'pipeline_tracker_screen.dart';
import 'profile_detail_screen.dart';

class CandidateMatchesScreen extends StatefulWidget {
  final Candidate targetCandidate;

  const CandidateMatchesScreen({
    super.key,
    required this.targetCandidate,
  });

  @override
  State<CandidateMatchesScreen> createState() => _CandidateMatchesScreenState();
}

class _CandidateMatchesScreenState extends State<CandidateMatchesScreen> {
  bool _isLoading = true;
  bool _strictOnly = true;
  List<MatchEvaluationResult> _matches = [];
  int _totalOppositeCandidatesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMatchingCandidates();
  }

  Future<void> _loadMatchingCandidates() async {
    setState(() => _isLoading = true);

    // Fetch all candidates of complementary gender
    final oppositeGender = widget.targetCandidate.isMale ? 'Female' : 'Male';
    final candidates = await AppDatabase.instance.getAllCandidates(
      gender: oppositeGender,
    );

    _totalOppositeCandidatesCount = candidates.length;

    // Run offline matching engine
    final results = MatchingEngine.findMatches(
      target: widget.targetCandidate,
      candidatePool: candidates,
      strictOnly: _strictOnly,
    );

    setState(() {
      _matches = results;
      _isLoading = false;
    });
  }

  Future<void> _initiateProposal(MatchEvaluationResult match) async {
    final potential = match.candidate;
    final male = widget.targetCandidate.isMale ? widget.targetCandidate : potential;
    final female = widget.targetCandidate.isFemale ? widget.targetCandidate : potential;

    final proposal = Proposal(
      id: const Uuid().v4(),
      maleCandidateId: male.id,
      femaleCandidateId: female.id,
      maleName: male.name,
      femaleName: female.name,
      sect: male.sect,
      caste: male.caste,
      stage: PipelineStage.proposalSent,
      notes:
          'Proposal initiated on ${DateTime.now().toLocal()}. Compatibility Score: ${match.compatibilityScore.toStringAsFixed(0)}%',
    );

    await AppDatabase.instance.insertProposal(proposal);

    // Update candidate pipeline statuses locally
    await AppDatabase.instance.updateCandidate(
      widget.targetCandidate.copyWith(pipelineStatus: PipelineStage.proposalSent),
    );
    await AppDatabase.instance.updateCandidate(
      potential.copyWith(pipelineStatus: PipelineStage.proposalSent),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proposal between ${male.name} and ${female.name} moved to "Proposal Sent"!',
        ),
        backgroundColor: const Color(0xFF047857),
        action: SnackBarAction(
          label: 'View Pipeline',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PipelineTrackerScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.targetCandidate;

    return Scaffold(
      appBar: AppBar(
        title: Text('Matches for ${target.name}'),
      ),
      body: Column(
        children: [
          // Target Candidate Summary Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: target.isMale
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFFDF2F8),
              border: Border(
                bottom: BorderSide(
                  color: target.isMale
                      ? Colors.blue.shade200
                      : Colors.pink.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: target.isMale
                      ? Colors.blue.shade700
                      : Colors.pink.shade700,
                  foregroundColor: Colors.white,
                  child: Icon(target.isMale ? Icons.man : Icons.woman),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${target.name} (${target.gender})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${target.age} yrs • ${target.heightDisplay} • ${target.sect} • ${target.caste}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Edu: ${target.education} (Tier ${target.educationTier.rank})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Strict Rules Toggle & Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${_matches.length} matching candidate(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    const Text('Strict Only', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: _strictOnly,
                      activeColor: const Color(0xFF047857),
                      onChanged: (val) {
                        setState(() => _strictOnly = val);
                        _loadMatchingCandidates();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Matches List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _matches.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Eligible Matches Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tested against $_totalOppositeCandidatesCount ${target.isMale ? 'Female' : 'Male'} candidate profiles in local database.\n'
                                'Strict matching requires: Exact Sect (${target.sect}), Exact Caste (${target.caste}), Male Height > Female Height, and Male Edu >= Female Edu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _strictOnly = false);
                                  _loadMatchingCandidates();
                                },
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Show Incompatible Candidates (Audit Log)'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _matches.length,
                        itemBuilder: (context, index) {
                          final match = _matches[index];
                          return MatchScoreCard(
                            targetCandidate: target,
                            matchResult: match,
                            onInitiateProposal: () => _initiateProposal(match),
                            onViewProfile: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileDetailScreen(
                                    candidateId: match.candidate.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

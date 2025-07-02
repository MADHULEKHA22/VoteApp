import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_voting_app/resultsscreen.dart';
import 'dart:convert';

const String backendBaseUrl = 'https://onlinevotingapp-e375b.web.app/api';


class VoteScreen extends StatefulWidget {
  final String uid;
  final int secondsLeft;

  const VoteScreen({
    required this.uid,
    required this.secondsLeft,
    super.key,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String selectedCandidate = '';
  bool hasVoted = false;
  bool isSubmitting = false;

  final List<Map<String, String>> candidates = [
    {"id": "party1", "name": "Party A", "icon": "🗳️"},
    {"id": "party2", "name": "Party B", "icon": "🏛️"},
    {"id": "party3", "name": "Party C", "icon": "🦅"},
    {"id": "party4", "name": "Party D", "icon": "⚖️"},
  ];

  Future<void> castVote() async {
    if (selectedCandidate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select a party first.")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final res = await http.post(
        Uri.parse('$backendBaseUrl/vote'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": widget.uid,
          "candidate_id": selectedCandidate,
        }),
      );

      if (res.statusCode == 200) {
        setState(() {
          hasVoted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Your vote has been successfully cast!")),
        );
      } else {
        final error = json.decode(res.body)['detail'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ $error")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to submit vote: $e")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Vote Now"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to the Voting Panel",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose your preferred party and cast your vote securely.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Your Party",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.count(
                crossAxisCount: isWideScreen ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                physics: const BouncingScrollPhysics(),
                children: candidates.map((party) {
                  final isSelected = selectedCandidate == party['id'];
                  return GestureDetector(
                    onTap: () {
                      if (!hasVoted && widget.secondsLeft > 0) {
                        setState(() => selectedCandidate = party['id']!);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            party['icon']!,
                            style: TextStyle(
                              fontSize: isWideScreen ? 40 : 36,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            party['name']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: (hasVoted ||
                      selectedCandidate.isEmpty ||
                      widget.secondsLeft <= 0 ||
                      isSubmitting)
                  ? null
                  : castVote,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.how_to_vote),
              label: Text(
                hasVoted
                    ? "You have voted"
                    : isSubmitting
                        ? "Submitting..."
                        : "Cast Vote",
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResultsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart, color: Colors.deepPurple),
              label: const Text(
                "View Results",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.deepPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

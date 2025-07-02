import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_voting_app/profilescreen.dart';
import 'package:online_voting_app/resultsscreen.dart';
import 'package:online_voting_app/votescreen.dart';
import 'package:online_voting_app/faqscreen.dart';
import 'package:online_voting_app/find_poll_station_screen.dart';

const String backendBaseUrl = 'https://onlinevotingapp-e375b.web.app/api';


class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({required this.uid, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int secondsLeft = 0;
  Timer? countdownTimer;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchTimeLeft();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(_glowController);

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> fetchTimeLeft() async {
    try {
      final res = await http.get(Uri.parse('$backendBaseUrl/time_left'));
      if (res.statusCode == 200) {
        setState(() {
          secondsLeft = json.decode(res.body)['seconds'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching time: $e");
    }
  }

  Map<String, String> breakdownTime(int seconds) {
    final d = Duration(seconds: seconds);
    return {
      'days': d.inDays.toString().padLeft(2, '0'),
      'hours': (d.inHours % 24).toString().padLeft(2, '0'),
      'minutes': (d.inMinutes % 60).toString().padLeft(2, '0'),
      'seconds': (d.inSeconds % 60).toString().padLeft(2, '0'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      buildHomeTab(),
      ProfileScreen(uid: widget.uid),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0 || index == 1) {
            setState(() {
              _currentIndex = index;
            });
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VoteScreen(
                  uid: widget.uid,
                  secondsLeft: secondsLeft,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ResultsScreen(),
              ),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Election',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Poll History',
          ),
        ],
      ),
    );
  }

  Widget buildHomeTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final time = breakdownTime(secondsLeft);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Text(
                "Welcome to Digital Voting!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  shadows: [
                    Shadow(
                      color: Colors.deepPurple.withOpacity(0.5),
                      blurRadius: _glowAnimation.value,
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          /// Countdown Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Assembly Election",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "General Election to legislative assembly of Tamil Nadu 2024",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                /// Time Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _timeBox(label: "days", value: time['days']!),
                    _timeBox(label: "hours", value: time['hours']!),
                    _timeBox(label: "mins", value: time['minutes']!),
                    _timeBox(label: "sec", value: time['seconds']!),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  "You have ${time['days']} days left to vote. Don't miss your chance!",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoteScreen(
                          uid: widget.uid,
                          secondsLeft: secondsLeft,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Vote Now",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// Grid Buttons
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardButton(
                icon: Icons.how_to_vote,
                label: "Vote Now",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoteScreen(
                        uid: widget.uid,
                        secondsLeft: secondsLeft,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardButton(
                icon: Icons.bar_chart,
                label: "View Results",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResultsScreen(),
                    ),
                  );
                },
              ),
              _buildDashboardButton(
                icon: Icons.info_outline,
                label: "FAQs & Education",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FAQScreen(),
                    ),
                  );
                },
              ),
              _buildDashboardButton(
                icon: Icons.map,
                label: "Find Poll Station",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FindPollStationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox({required String label, required String value}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        )
      ],
    );
  }

  Widget _buildDashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

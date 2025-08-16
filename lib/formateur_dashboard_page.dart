import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formateur_courses_page.dart';
import 'student_tracking_page.dart';
import 'quiz_management_page.dart';
import 'formateur_messages_page.dart';
import 'evaluations_page.dart';
import 'formateur_analytics_page.dart';
import 'formateur_profile_page.dart';

class FormateurDashboardPage extends StatefulWidget {
  final String userName;

  const FormateurDashboardPage({super.key, required this.userName});

  @override
  State<FormateurDashboardPage> createState() => _FormateurDashboardPageState();
}

class _FormateurDashboardPageState extends State<FormateurDashboardPage> {
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('formateurId', isEqualTo: user.uid)
          .get();

      final enrollmentsQuery = await FirebaseFirestore.instance
          .collection('enrollments')
          .get();

      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('formateurId', isEqualTo: user.uid)
          .get();

      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('formateurId', isEqualTo: user.uid)
          .where('hasUnread', isEqualTo: true)
          .get();

      final myCourseIds = coursesSnapshot.docs.map((doc) => doc.id).toList();
      final myEnrollments = enrollmentsQuery.docs.where((enrollment) {
        final data = enrollment.data();
        return myCourseIds.contains(data['courseId']);
      }).toList();

      setState(() {
        _dashboardStats = {
          'totalCourses': coursesSnapshot.docs.length,
          'totalStudents': myEnrollments.length,
          'totalQuizzes': quizzesSnapshot.docs.length,
          'unreadMessages': messagesSnapshot.docs.length,
          'recentEnrollments': myEnrollments.where((e) {
            final data = e.data();
            final enrolledAt = data['enrolledAt'] as Timestamp?;
            if (enrolledAt == null) return false;
            final daysDiff = DateTime.now()
                .difference(enrolledAt.toDate())
                .inDays;
            return daysDiff <= 7;
          }).length,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 242, 245),
      appBar: AppBar(
        title: const Text(
          'Dashboard Formateur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bienvenue, ${widget.userName} 👋",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildStatCard(
                          "Cours",
                          _dashboardStats['totalCourses'],
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormateurCoursesPage(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          "Étudiants",
                          _dashboardStats['totalStudents'],
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentTrackingPage(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          "Quiz",
                          _dashboardStats['totalQuizzes'],
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuizManagementPage(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          "Messages non lus",
                          _dashboardStats['unreadMessages'],
                          Colors.red,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormateurMessagesPage(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard("Évaluations", "-", Colors.purple, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EvaluationsPage(),
                            ),
                          );
                        }),
                        _buildStatCard(
                          "Analytique",
                          "-",
                          Colors.deepPurpleAccent,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormateurAnalyticsPage(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard("Profil", "-", Colors.teal, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FormateurProfilePage(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    dynamic value,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

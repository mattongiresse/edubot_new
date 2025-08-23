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
  int _selectedIndex = 0;

  // Liste des pages avec la page d'accueil (cours) par défaut
  late List<Widget> _pages;

  // Configuration des onglets
  final List<Map<String, dynamic>> _tabsConfig = [
    {
      'icon': Icons.home,
      'title': 'Accueil',
      'color': Colors.deepPurple,
      'statKey': null,
    },
    {
      'icon': Icons.book,
      'title': 'Mes Cours',
      'color': Colors.blue,
      'statKey': 'totalCourses',
    },
    {
      'icon': Icons.people,
      'title': 'Étudiants',
      'color': Colors.green,
      'statKey': 'totalStudents',
    },
    {
      'icon': Icons.quiz,
      'title': 'Quiz',
      'color': Colors.orange,
      'statKey': 'totalQuizzes',
    },
    {
      'icon': Icons.mail,
      'title': 'Messages',
      'color': Colors.red,
      'statKey': 'unreadMessages',
    },
    {
      'icon': Icons.assessment,
      'title': 'Évaluations',
      'color': Colors.purple,
      'statKey': null,
    },
    {
      'icon': Icons.analytics,
      'title': 'Analytique',
      'color': Colors.deepPurpleAccent,
      'statKey': null,
    },
    {
      'icon': Icons.person,
      'title': 'Profil',
      'color': Colors.teal,
      'statKey': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomePage(),
      const FormateurCoursesImproved(),
      const StudentTrackingPage(),
      const QuizManagementPage(),
      const FormateurMessagesPage(),
      const EvaluationsPage(),
      const FormateurAnalyticsPage(),
      const FormateurProfilePage(),
    ];
    _loadDashboardStats()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((e) {
          if (mounted) setState(() => _isLoadingStats = false);
        });
  }

  Future<void> _loadDashboardStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingStats = false);
      return;
    }

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
      print('Erreur lors du chargement des stats: $e');
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.waving_hand,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${widget.userName}!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Prêt à inspirer vos étudiants aujourd\'hui ?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_isLoadingStats) ...[
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Cours',
                  _dashboardStats['totalCourses']?.toString() ?? '0',
                  Icons.book,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Étudiants',
                  _dashboardStats['totalStudents']?.toString() ?? '0',
                  Icons.people,
                  Colors.green,
                ),
                _buildStatCard(
                  'Quiz',
                  _dashboardStats['totalQuizzes']?.toString() ?? '0',
                  Icons.quiz,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Messages non lus',
                  _dashboardStats['unreadMessages']?.toString() ?? '0',
                  Icons.mail,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onItemTapped(1),
                  icon: const Icon(Icons.book),
                  label: const Text('Voir mes cours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onItemTapped(3),
                  icon: const Icon(Icons.quiz),
                  label: const Text('Créer un quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                _tabsConfig[_selectedIndex]['title'],
                style: const TextStyle(fontSize: 20),
              ),
              backgroundColor: _tabsConfig[_selectedIndex]['color'],
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        color: Colors.grey[50],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabsConfig.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;
              final isSelected = _selectedIndex == index;
              final statValue = config['statKey'] != null
                  ? _dashboardStats[config['statKey']]?.toString() ?? '0'
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? config['color'].withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isSelected
                                ? config['color'].withOpacity(0.15)
                                : Colors.transparent,
                            child: Icon(
                              config['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : config['color'],
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? config['color']
                                : Colors.grey[600],
                          ),
                        ),
                        SizedBox(
                          height: 16,
                          child: statValue != null
                              ? Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: config['color'],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    statValue,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

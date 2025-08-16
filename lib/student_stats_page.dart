import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentStatsPage extends StatefulWidget {
  const StudentStatsPage({super.key});

  @override
  State<StudentStatsPage> createState() => _StudentStatsPageState();
}

class _StudentStatsPageState extends State<StudentStatsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Données des statistiques
  Map<String, dynamic> _globalStats = {};
  List<Map<String, dynamic>> _courseProgress = [];
  List<Map<String, dynamic>> _quizResults = [];
  Map<String, int> _categoryStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentStatistics();
  }

  Future<void> _loadStudentStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Récupérer les inscriptions aux cours
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: user.uid)
          .get();

      // Récupérer les tentatives de quiz
      final quizAttemptsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: user.uid)
          .get();

      // Récupérer les détails des cours pour les catégories
      List<String> courseIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      QuerySnapshot coursesSnapshot;
      if (courseIds.isNotEmpty) {
        coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, whereIn: courseIds)
            .get();
      } else {
        coursesSnapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, isEqualTo: 'non-existent')
            .get();
      }

      // Calculer les statistiques globales
      _calculateGlobalStats(
        enrollmentsSnapshot.docs,
        quizAttemptsSnapshot.docs,
      );

      // Calculer la progression des cours
      _calculateCourseProgress(enrollmentsSnapshot.docs, coursesSnapshot.docs);

      // Calculer les résultats des quiz
      _calculateQuizResults(quizAttemptsSnapshot.docs);

      // Calculer les statistiques par catégorie
      _calculateCategoryStats(enrollmentsSnapshot.docs, coursesSnapshot.docs);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateGlobalStats(
    List<QueryDocumentSnapshot> enrollments,
    List<QueryDocumentSnapshot> quizAttempts,
  ) {
    int totalCourses = enrollments.length;
    int completedCourses = enrollments.where((e) {
      final data = e.data() as Map<String, dynamic>;
      return data['isCompleted'] == true;
    }).length;

    double averageProgress = 0;
    if (enrollments.isNotEmpty) {
      int totalProgress = enrollments.fold(0, (sum, e) {
        final data = e.data() as Map<String, dynamic>;
        return sum + (data['progress'] ?? 0) as int;
      });
      averageProgress = totalProgress / enrollments.length;
    }

    double averageQuizScore = 0;
    if (quizAttempts.isNotEmpty) {
      int totalScore = quizAttempts.fold(0, (sum, q) {
        final data = q.data() as Map<String, dynamic>;
        return sum + (data['score'] ?? 0) as int;
      });
      averageQuizScore = totalScore / quizAttempts.length;
    }

    int totalQuizzes = quizAttempts.length;
    int passedQuizzes = quizAttempts.where((q) {
      final data = q.data() as Map<String, dynamic>;
      return (data['score'] ?? 0) >= 70;
    }).length;

    _globalStats = {
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'averageProgress': averageProgress.round(),
      'totalQuizzes': totalQuizzes,
      'passedQuizzes': passedQuizzes,
      'averageQuizScore': averageQuizScore.round(),
      'completionRate': totalCourses > 0
          ? ((completedCourses / totalCourses) * 100).round()
          : 0,
    };
  }

  void _calculateCourseProgress(
    List<QueryDocumentSnapshot> enrollments,
    List<QueryDocumentSnapshot> courses,
  ) {
    _courseProgress = [];

    for (var enrollment in enrollments) {
      final enrollData = enrollment.data() as Map<String, dynamic>;

      // Trouver le cours correspondant
      final course = courses.firstWhere(
        (c) => c.id == enrollData['courseId'],
        orElse: () => courses.first, // Fallback si pas trouvé
      );

      if (courses.isNotEmpty) {
        final courseData = course.data() as Map<String, dynamic>;

        _courseProgress.add({
          'title': enrollData['courseTitle'] ?? courseData['title'] ?? 'Cours',
          'category': courseData['category'] ?? 'Non catégorisé',
          'progress': enrollData['progress'] ?? 0,
          'isCompleted': enrollData['isCompleted'] ?? false,
          'enrolledAt': enrollData['enrolledAt'],
        });
      }
    }
  }

  void _calculateQuizResults(List<QueryDocumentSnapshot> quizAttempts) {
    _quizResults = quizAttempts.map((q) {
      final data = q.data() as Map<String, dynamic>;
      return {
        'title': data['quizTitle'] ?? 'Quiz',
        'score': data['score'] ?? 0,
        'submittedAt': data['submittedAt'],
        'passed': (data['score'] ?? 0) >= 70,
      };
    }).toList();
  }

  void _calculateCategoryStats(
    List<QueryDocumentSnapshot> enrollments,
    List<QueryDocumentSnapshot> courses,
  ) {
    _categoryStats = {};

    for (var enrollment in enrollments) {
      final enrollData = enrollment.data() as Map<String, dynamic>;

      // Trouver le cours correspondant
      final course = courses.where((c) => c.id == enrollData['courseId']);

      if (course.isNotEmpty) {
        final courseData = course.first.data() as Map<String, dynamic>;
        final category = courseData['category'] ?? 'Non catégorisé';

        _categoryStats[category] = (_categoryStats[category] ?? 0) + 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progression'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProgressTab(),
                _buildQuizTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Métriques principales
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildMetricCard(
                'Cours Suivis',
                _globalStats['totalCourses'].toString(),
                Icons.book,
                Colors.blue,
              ),
              _buildMetricCard(
                'Cours Terminés',
                _globalStats['completedCourses'].toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildMetricCard(
                'Progression Moy.',
                '${_globalStats['averageProgress']}%',
                Icons.trending_up,
                Colors.orange,
              ),
              _buildMetricCard(
                'Score Quiz Moy.',
                '${_globalStats['averageQuizScore']}%',
                Icons.quiz,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Graphique en secteurs des catégories
          if (_categoryStats.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Répartition par Catégories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          sections: _buildCategorySections(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildCategoryLegend(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Taux de réussite global
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Performance Globale',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceIndicator(
                          'Taux de Complétion',
                          _globalStats['completionRate'],
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceIndicator(
                          'Taux de Réussite Quiz',
                          _globalStats['totalQuizzes'] > 0
                              ? ((_globalStats['passedQuizzes'] /
                                            _globalStats['totalQuizzes']) *
                                        100)
                                    .round()
                              : 0,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progression par cours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📈 Progression par Cours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_courseProgress.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.school, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun cours suivi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _courseProgress.length,
                      itemBuilder: (context, index) {
                        final course = _courseProgress[index];
                        return _buildCourseProgressCard(course);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Graphique de progression dans le temps (simulation)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Évolution de la Progression',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateProgressSpots(),
                            isCurved: true,
                            color: Colors.deepPurple,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepPurple.withOpacity(0.1),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('S${value.toInt() + 1}');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistiques générales des quiz
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧠 Statistiques Quiz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuizStatCard(
                          'Total Quiz',
                          _globalStats['totalQuizzes'].toString(),
                          Icons.quiz,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuizStatCard(
                          'Quiz Réussis',
                          _globalStats['passedQuizzes'].toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuizStatCard(
                          'Score Moyen',
                          '${_globalStats['averageQuizScore']}%',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuizStatCard(
                          'Taux Réussite',
                          '${_globalStats['totalQuizzes'] > 0 ? ((_globalStats['passedQuizzes'] / _globalStats['totalQuizzes']) * 100).round() : 0}%',
                          Icons.psychology,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Liste détaillée des résultats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Historique des Quiz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_quizResults.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.quiz, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun quiz passé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quizResults.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizResults[index];
                        return _buildQuizResultCard(quiz);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator(String title, int percentage, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$percentage%',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCourseProgressCard(Map<String, dynamic> course) {
    final progress = course['progress'] ?? 0;
    final isCompleted = course['isCompleted'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.green : Colors.blue,
          child: Icon(
            isCompleted ? Icons.check : Icons.book,
            color: Colors.white,
          ),
        ),
        title: Text(
          course['title'] ?? 'Cours',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie: ${course['category']}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        trailing: Text(
          '$progress%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildQuizStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResultCard(Map<String, dynamic> quiz) {
    final score = quiz['score'] ?? 0;
    final passed = quiz['passed'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: passed ? Colors.green : Colors.red,
          child: Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(quiz['title'] ?? 'Quiz'),
        subtitle: Text(_formatDate(quiz['submittedAt'])),
        trailing: Icon(
          passed ? Icons.check_circle : Icons.cancel,
          color: passed ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildCategorySections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return _categoryStats.entries.map((entry) {
      final index = _categoryStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCategoryLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return _categoryStats.entries.map((entry) {
      final index = _categoryStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(entry.key, style: const TextStyle(fontSize: 12)),
        ],
      );
    }).toList();
  }

  List<FlSpot> _generateProgressSpots() {
    // Simulation de progression dans le temps
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), (i * 15 + 10).toDouble()));
    }
    return spots;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

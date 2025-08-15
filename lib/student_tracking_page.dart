import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentTrackingPage extends StatefulWidget {
  const StudentTrackingPage({super.key});

  @override
  State<StudentTrackingPage> createState() => _StudentTrackingPageState();
}

class _StudentTrackingPageState extends State<StudentTrackingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCourseFilter = 'Tous';
  List<String> _myCourses = ['Tous'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('formateurId', isEqualTo: user.uid)
        .get();

    setState(() {
      _myCourses = ['Tous'];
      for (var doc in coursesSnapshot.docs) {
        _myCourses.add(doc.data()['title'] ?? 'Sans titre');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Suivi des Étudiants'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Étudiants'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
            Tab(icon: Icon(Icons.assignment), text: 'Progression'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtre par cours
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedCourseFilter,
              decoration: const InputDecoration(
                labelText: 'Filtrer par cours',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: _myCourses
                  .map(
                    (course) =>
                        DropdownMenuItem(value: course, child: Text(course)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCourseFilter = val!),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsList(),
                _buildStatistics(),
                _buildProgressOverview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnrollmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun étudiant inscrit',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final enrollments = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            final data = enrollment.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    (data['studentName'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  data['studentName'] ?? 'Étudiant inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cours: ${data['courseTitle'] ?? 'N/A'}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (data['progress'] ?? 0) / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(data['progress'] ?? 0),
                      ),
                    ),
                    Text('${data['progress'] ?? 0}% complété'),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentDetailRow(
                          'Date d\'inscription',
                          _formatDate(data['enrolledAt']),
                        ),
                        _buildStudentDetailRow(
                          'Statut',
                          data['isCompleted'] == true ? 'Terminé' : 'En cours',
                        ),
                        _buildStudentDetailRow(
                          'Dernière activité',
                          _formatDate(data['lastActivity']),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _sendMessage(data['studentId']),
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _viewDetails(enrollment.id),
                              icon: const Icon(Icons.visibility),
                              label: const Text('Détails'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnrollmentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final enrollments = snapshot.data!.docs;
        final stats = _calculateStatistics(enrollments);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Cartes de statistiques
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Étudiants',
                    stats['totalStudents'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Cours Terminés',
                    stats['completedCourses'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'En Progression',
                    stats['inProgress'].toString(),
                    Icons.timeline,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Taux de Réussite',
                    '${stats['successRate']}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Graphique de progression
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition des Progressions',
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
                            sections: _buildPieChartSections(stats),
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
      },
    );
  }

  Widget _buildProgressOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEnrollmentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final enrollments = snapshot.data!.docs;

        // Grouper par cours
        Map<String, List<Map<String, dynamic>>> courseGroups = {};
        for (var doc in enrollments) {
          final data = doc.data() as Map<String, dynamic>;
          final courseTitle = data['courseTitle'] ?? 'Sans titre';

          if (!courseGroups.containsKey(courseTitle)) {
            courseGroups[courseTitle] = [];
          }
          courseGroups[courseTitle]!.add(data);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courseGroups.length,
          itemBuilder: (context, index) {
            final courseTitle = courseGroups.keys.elementAt(index);
            final students = courseGroups[courseTitle]!;
            final avgProgress =
                students
                    .map((s) => s['progress'] ?? 0)
                    .reduce((a, b) => a + b) /
                students.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            courseTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text('${students.length} étudiants'),
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progression moyenne: ${avgProgress.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: avgProgress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(avgProgress.toInt()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: students.map((student) {
                        final progress = student['progress'] ?? 0;
                        return Chip(
                          avatar: CircleAvatar(
                            radius: 12,
                            backgroundColor: _getProgressColor(progress),
                            child: Text(
                              '$progress%',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          label: Text(
                            student['studentName']?.split(' ').first ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> stats) {
    return [
      PieChartSectionData(
        color: Colors.green,
        value: stats['completedCourses']!.toDouble(),
        title: 'Terminé',
        radius: 60,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: stats['inProgress']!.toDouble(),
        title: 'En cours',
        radius: 60,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: stats['notStarted']!.toDouble(),
        title: 'Non commencé',
        radius: 60,
      ),
    ];
  }

  Stream<QuerySnapshot> _getEnrollmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Récupérer d'abord les cours du formateur
    return FirebaseFirestore.instance
        .collection('courses')
        .where('formateurId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((coursesSnapshot) async {
          if (coursesSnapshot.docs.isEmpty) {
            return FirebaseFirestore.instance
                .collection('enrollments')
                .where('courseId', isEqualTo: 'non-existent')
                .get();
          }

          final courseIds = coursesSnapshot.docs.map((doc) => doc.id).toList();

          return FirebaseFirestore.instance
              .collection('enrollments')
              .where('courseId', whereIn: courseIds)
              .get();
        });
  }

  Map<String, int> _calculateStatistics(
    List<QueryDocumentSnapshot> enrollments,
  ) {
    int totalStudents = enrollments.length;
    int completedCourses = 0;
    int inProgress = 0;
    int notStarted = 0;

    for (var enrollment in enrollments) {
      final data = enrollment.data() as Map<String, dynamic>;
      final progress = data['progress'] ?? 0;

      if (progress == 100) {
        completedCourses++;
      } else if (progress > 0) {
        inProgress++;
      } else {
        notStarted++;
      }
    }

    int successRate = totalStudents > 0
        ? ((completedCourses / totalStudents) * 100).round()
        : 0;

    return {
      'totalStudents': totalStudents,
      'completedCourses': completedCourses,
      'inProgress': inProgress,
      'notStarted': notStarted,
      'successRate': successRate,
    };
  }

  Color _getProgressColor(int progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  void _sendMessage(String studentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de message à venir')),
    );
  }

  void _viewDetails(String enrollmentId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Détails complets à venir')));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

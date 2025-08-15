import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class EvaluationsPage extends StatefulWidget {
  const EvaluationsPage({super.key});

  @override
  State<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends State<EvaluationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedQuizFilter = 'Tous';
  List<String> _myQuizzes = ['Tous'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyQuizzes();
  }

  Future<void> _loadMyQuizzes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final quizzesSnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('formateurId', isEqualTo: user.uid)
        .get();

    setState(() {
      _myQuizzes = ['Tous'];
      for (var doc in quizzesSnapshot.docs) {
        _myQuizzes.add(doc.data()['title'] ?? 'Quiz sans titre');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Évaluations & Corrections'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'À Corriger'),
            Tab(icon: Icon(Icons.analytics), text: 'Analyses'),
            Tab(icon: Icon(Icons.grade), text: 'Notes'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtre par quiz
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedQuizFilter,
              decoration: const InputDecoration(
                labelText: 'Filtrer par quiz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: _myQuizzes
                  .map(
                    (quiz) => DropdownMenuItem(value: quiz, child: Text(quiz)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedQuizFilter = val!),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingCorrectionsTab(),
                _buildAnalyticsTab(),
                _buildGradesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCorrectionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPendingCorrectionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune correction en attente',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Tous les quiz ont été corrigés !',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final attempts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attempts.length,
          itemBuilder: (context, index) {
            final attempt = attempts[index];
            final data = attempt.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getPriorityColor(data['priority']),
                      child: const Icon(Icons.assignment, color: Colors.white),
                    ),
                    if (data['isUrgent'] == true)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  data['quizTitle'] ?? 'Quiz sans titre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Étudiant: ${data['studentName'] ?? 'Inconnu'}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Soumis: ${_formatDate(data['submittedAt'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(data['quizType']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['quizType'] ?? 'Standard',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _correctQuiz(attempt.id, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Corriger'),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                'Temps passé',
                                '${data['timeSpent'] ?? 0} minutes',
                                Icons.timer,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                'Questions',
                                '${(data['answers'] as List?)?.length ?? 0}',
                                Icons.quiz,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                'Tentative',
                                '${data['attemptNumber'] ?? 1}',
                                Icons.repeat,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                'Score auto',
                                data['autoScore'] != null
                                    ? '${data['autoScore']}%'
                                    : 'N/A',
                                Icons.auto_awesome,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _viewQuizDetails(attempt.id, data),
                                icon: const Icon(Icons.visibility),
                                label: const Text('Voir Détails'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _quickGrade(attempt.id, data),
                                icon: const Icon(Icons.flash_on),
                                label: const Text('Note Rapide'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
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

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAllAttemptsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final attempts = snapshot.data!.docs;
        final analytics = _calculateAnalytics(attempts);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Cartes de statistiques globales
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildAnalyticsCard(
                    'Total Évaluations',
                    analytics['totalEvaluations'].toString(),
                    Icons.assignment,
                    Colors.blue,
                  ),
                  _buildAnalyticsCard(
                    'Score Moyen',
                    '${analytics['averageScore']}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  _buildAnalyticsCard(
                    'À Corriger',
                    analytics['pendingCorrections'].toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildAnalyticsCard(
                    'Taux de Réussite',
                    '${analytics['successRate']}%',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Graphique de répartition des scores
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition des Scores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: analytics['maxScoreFrequency'].toDouble(),
                            barGroups: _buildScoreDistributionBars(
                              analytics['scoreDistribution'],
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Text('0-20%');
                                      case 1:
                                        return const Text('21-40%');
                                      case 2:
                                        return const Text('41-60%');
                                      case 3:
                                        return const Text('61-80%');
                                      case 4:
                                        return const Text('81-100%');
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Performance par quiz
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance par Quiz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...analytics['quizPerformance'].entries.map((entry) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[50],
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text(
                              '${entry.value['attempts']} tentatives',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${entry.value['averageScore']}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(
                                      entry.value['averageScore'],
                                    ),
                                  ),
                                ),
                                Text(
                                  'moyenne',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildGradesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getGradedAttemptsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune note attribuée',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final gradedAttempts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: gradedAttempts.length,
          itemBuilder: (context, index) {
            final attempt = gradedAttempts[index];
            final data = attempt.data() as Map<String, dynamic>;
            final score = data['finalScore'] ?? data['score'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(score),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  data['studentName'] ?? 'Étudiant inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz: ${data['quizTitle'] ?? 'N/A'}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Corrigé: ${_formatDate(data['gradedAt'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    if (data['feedback'] != null && data['feedback'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Commentaire: ${data['feedback']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('Voir détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier note'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Exporter'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleGradeAction(value.toString(), attempt.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
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

  void _correctQuiz(String attemptId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizCorrectionScreen(attemptId: attemptId, attemptData: data),
      ),
    );
  }

  void _viewQuizDetails(String attemptId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails - ${data['quizTitle']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        'Étudiant',
                        data['studentName'] ?? 'N/A',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailCard(
                        'Score Auto',
                        '${data['autoScore'] ?? 0}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        'Temps',
                        '${data['timeSpent'] ?? 0} min',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailCard(
                        'Tentative',
                        '${data['attemptNumber'] ?? 1}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Réponses:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: (data['answers'] as List?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final answer = (data['answers'] as List)[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Réponse: ${answer['selectedAnswer'] ?? 'Aucune'}',
                              ),
                              Text(
                                'Correct: ${answer['isCorrect'] == true ? 'Oui' : 'Non'}',
                                style: TextStyle(
                                  color: answer['isCorrect'] == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _correctQuiz(attemptId, data);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Corriger'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _quickGrade(String attemptId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _QuickGradeDialog(
        attemptId: attemptId,
        currentScore: data['autoScore'] ?? 0,
        onGraded: () => setState(() {}),
      ),
    );
  }

  void _handleGradeAction(
    String action,
    String attemptId,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'view':
        _viewQuizDetails(attemptId, data);
        break;
      case 'edit':
        _editGrade(attemptId, data);
        break;
      case 'export':
        _exportGrade(data);
        break;
    }
  }

  void _editGrade(String attemptId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _EditGradeDialog(
        attemptId: attemptId,
        currentData: data,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  void _exportGrade(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'export à venir')),
    );
  }

  Stream<QuerySnapshot> _getPendingCorrectionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('quiz_attempts')
        .where('formateurId', isEqualTo: user.uid)
        .where('isGraded', isEqualTo: false)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getAllAttemptsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('quiz_attempts')
        .where('formateurId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot> _getGradedAttemptsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('quiz_attempts')
        .where('formateurId', isEqualTo: user.uid)
        .where('isGraded', isEqualTo: true)
        .orderBy('gradedAt', descending: true)
        .snapshots();
  }

  Map<String, dynamic> _calculateAnalytics(
    List<QueryDocumentSnapshot> attempts,
  ) {
    int totalEvaluations = attempts.length;
    int pendingCorrections = 0;
    int totalScore = 0;
    int passedAttempts = 0;
    Map<String, Map<String, dynamic>> quizPerformance = {};
    List<int> scoreDistribution = [
      0,
      0,
      0,
      0,
      0,
    ]; // 0-20, 21-40, 41-60, 61-80, 81-100

    for (var attempt in attempts) {
      final data = attempt.data() as Map<String, dynamic>;
      final score = data['finalScore'] ?? data['score'] ?? 0;
      final quizTitle = data['quizTitle'] ?? 'Quiz sans titre';

      totalScore += score as int;

      if (data['isGraded'] != true) {
        pendingCorrections++;
      }

      if (score >= 60) {
        passedAttempts++;
      }

      // Distribution des scores
      if (score <= 20) {
        scoreDistribution[0]++;
      } else if (score <= 40) {
        scoreDistribution[1]++;
      } else if (score <= 60) {
        scoreDistribution[2]++;
      } else if (score <= 80) {
        scoreDistribution[3]++;
      } else {
        scoreDistribution[4]++;
      }

      // Performance par quiz
      if (!quizPerformance.containsKey(quizTitle)) {
        quizPerformance[quizTitle] = {
          'attempts': 0,
          'totalScore': 0,
          'averageScore': 0,
        };
      }
      quizPerformance[quizTitle]!['attempts']++;
      quizPerformance[quizTitle]!['totalScore'] += score;
    }

    // Calculer les moyennes
    for (var quiz in quizPerformance.keys) {
      int attempts = quizPerformance[quiz]!['attempts'];
      int total = quizPerformance[quiz]!['totalScore'];
      quizPerformance[quiz]!['averageScore'] = attempts > 0
          ? (total / attempts).round()
          : 0;
    }

    return {
      'totalEvaluations': totalEvaluations,
      'pendingCorrections': pendingCorrections,
      'averageScore': totalEvaluations > 0
          ? (totalScore / totalEvaluations).round()
          : 0,
      'successRate': totalEvaluations > 0
          ? ((passedAttempts / totalEvaluations) * 100).round()
          : 0,
      'scoreDistribution': scoreDistribution,
      'maxScoreFrequency': scoreDistribution.reduce((a, b) => a > b ? a : b),
      'quizPerformance': quizPerformance,
    };
  }

  List<BarChartGroupData> _buildScoreDistributionBars(List<int> distribution) {
    return List.generate(distribution.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: distribution[index].toDouble(),
            color: Colors.deepPurple,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'QCM':
        return Colors.blue;
      case 'Rédaction':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==========================
// Dialogs placeholders
// ==========================

class QuizCorrectionScreen extends StatelessWidget {
  final String attemptId;
  final Map<String, dynamic> attemptData;
  const QuizCorrectionScreen({
    super.key,
    required this.attemptId,
    required this.attemptData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Correction du quiz")),
      body: Center(child: Text("Correction pour $attemptId")),
    );
  }
}

class _QuickGradeDialog extends StatelessWidget {
  final String attemptId;
  final int currentScore;
  final VoidCallback onGraded;
  const _QuickGradeDialog({
    required this.attemptId,
    required this.currentScore,
    required this.onGraded,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note Rapide'),
      content: Text('Attribuer rapidement une note pour $attemptId'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            onGraded();
            Navigator.pop(context);
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _EditGradeDialog extends StatelessWidget {
  final String attemptId;
  final Map<String, dynamic> currentData;
  final VoidCallback onUpdated;
  const _EditGradeDialog({
    required this.attemptId,
    required this.currentData,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController scoreController = TextEditingController(
      text: (currentData['finalScore'] ?? '').toString(),
    );

    return AlertDialog(
      title: const Text('Modifier la note'),
      content: TextField(
        controller: scoreController,
        decoration: const InputDecoration(labelText: 'Nouvelle note (%)'),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Mettre à jour Firestore ici
            onUpdated();
            Navigator.pop(context);
          },
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}

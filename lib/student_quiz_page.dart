import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quiz & Évaluations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Quiz Disponibles'),
            Tab(icon: Icon(Icons.history), text: 'Mes Résultats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAvailableQuizzesTab(), _buildMyResultsTab()],
      ),
    );
  }

  Widget _buildAvailableQuizzesTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!enrollmentSnapshot.hasData ||
            enrollmentSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun cours suivi',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Inscrivez-vous à des cours pour accéder aux quiz',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Récupérer les cours de l'étudiant
        final enrollments = enrollmentSnapshot.data!.docs;
        final courseIds = enrollments.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['courseId'] as String;
        }).toList();

        if (courseIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun quiz disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Vos formateurs n\'ont pas encore créé de quiz',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .where('courseId', whereIn: courseIds)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, quizSnapshot) {
            if (!quizSnapshot.hasData || quizSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun quiz disponible',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Vos formateurs n\'ont pas encore créé de quiz',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final quizzes = quizSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final data = quiz.data() as Map<String, dynamic>;

                return _buildQuizCard(quiz.id, data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuizCard(String quizId, Map<String, dynamic> data) {
    final questions = data['questions'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du quiz
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Quiz sans titre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cours: ${data['course'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${questions.length} questions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu du quiz
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['description'] != null &&
                    data['description'].isNotEmpty)
                  Text(
                    data['description'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),

                // Informations du quiz
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      '${data['duration'] ?? 0} min',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.repeat,
                      '${data['maxAttempts'] ?? 1} tentatives',
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bouton pour commencer le quiz
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startQuiz(quizId, data),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Commencer le Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyResultsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun résultat',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Passez votre premier quiz pour voir vos résultats',
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

            return _buildResultCard(data);
          },
        );
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final score = data['score'] ?? 0;
    final Color scoreColor = _getScoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor,
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
          data['quizTitle'] ?? 'Quiz',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $score%'),
            Text(_formatDate(data['submittedAt'])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              score >= 70 ? Icons.check_circle : Icons.cancel,
              color: scoreColor,
            ),
            Text(
              score >= 70 ? 'Réussi' : 'Échec',
              style: TextStyle(
                color: scoreColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _showDetailedResult(data),
      ),
    );
  }

  void _startQuiz(String quizId, Map<String, dynamic> quizData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quizData['title'] ?? 'Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durée: ${quizData['duration']} minutes'),
            Text('Questions: ${(quizData['questions'] as List?)?.length ?? 0}'),
            Text('Tentatives autorisées: ${quizData['maxAttempts']}'),
            const SizedBox(height: 16),
            const Text(
              'Êtes-vous prêt à commencer ce quiz ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToQuizTaking(quizId, quizData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _navigateToQuizTaking(String quizId, Map<String, dynamic> quizData) {
    // Navigation vers la page de passage de quiz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizTakingPage(quizId: quizId, quizData: quizData),
      ),
    );
  }

  void _showDetailedResult(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultat: ${data['quizTitle']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${data['score']}%'),
            Text('Date: ${_formatDate(data['submittedAt'])}'),
            Text('Temps passé: ${data['timeSpent'] ?? 'N/A'} minutes'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getScoreColor(data['score'] ?? 0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['score'] >= 70 ? '✅ Quiz réussi !' : '❌ Quiz échoué',
                style: TextStyle(
                  color: _getScoreColor(data['score'] ?? 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Page pour passer un quiz
class QuizTakingPage extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quizData;

  const QuizTakingPage({
    super.key,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _isSubmitting = false;
  late int _timeRemaining;
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Map<String, dynamic>>.from(
      widget.quizData['questions'] ?? [],
    );
    _selectedAnswers = List<int?>.filled(_questions.length, null);
    _timeRemaining = (widget.quizData['duration'] ?? 30) * 60; // en secondes
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeRemaining > 0) {
        setState(() => _timeRemaining--);
        _startTimer();
      } else if (mounted && _timeRemaining == 0) {
        _submitQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Aucune question disponible')),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.quizData['title'] ?? 'Quiz'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${(_timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} sur ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / _questions.length * 100).toInt()}%',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          // Question et réponses
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion['questionText'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              (currentQuestion['options'] as List?)?.length ??
                              0,
                          itemBuilder: (context, optionIndex) {
                            final options = currentQuestion['options'] as List;
                            final isSelected =
                                _selectedAnswers[_currentQuestionIndex] ==
                                optionIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[_currentQuestionIndex] =
                                      optionIndex;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepPurple.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.deepPurple
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        options[optionIndex],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _currentQuestionIndex--);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex < _questions.length - 1
                        ? () {
                            setState(() => _currentQuestionIndex++);
                          }
                        : _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentQuestionIndex < _questions.length - 1
                                ? 'Suivant'
                                : 'Terminer',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Calculer le score
      int correctAnswers = 0;
      for (int i = 0; i < _questions.length; i++) {
        final correctIndex = _questions[i]['correctAnswerIndex'] ?? -1;
        if (_selectedAnswers[i] == correctIndex) {
          correctAnswers++;
        }
      }

      final score = ((correctAnswers / _questions.length) * 100).round();

      // Récupérer les infos utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final studentName =
          '${userDoc.data()?['prenom'] ?? ''} ${userDoc.data()?['nom'] ?? ''}';

      // Enregistrer le résultat
      await FirebaseFirestore.instance.collection('quiz_attempts').add({
        'studentId': user.uid,
        'studentName': studentName.trim(),
        'quizId': widget.quizId,
        'quizTitle': widget.quizData['title'],
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': _questions.length,
        'answers': _selectedAnswers,
        'timeSpent':
            (widget.quizData['duration'] ?? 30) - (_timeRemaining ~/ 60),
        'submittedAt': FieldValue.serverTimestamp(),
        'formateurId': widget.quizData['formateurId'],
      });

      if (!mounted) return;

      // Afficher le résultat
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            score >= 70 ? '🎉 Félicitations !' : '📚 Continuez vos efforts',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre score: $score%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('$correctAnswers bonnes réponses sur ${_questions.length}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: score >= 70
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score >= 70 ? 'Quiz réussi !' : 'Quiz échoué',
                  style: TextStyle(
                    color: score >= 70 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Retour aux Quiz'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la soumission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

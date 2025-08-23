import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizManagementPage extends StatefulWidget {
  const QuizManagementPage({super.key});

  @override
  State<QuizManagementPage> createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _quizFormKey = GlobalKey<FormState>();

  // Contrôleurs pour la création de quiz
  final TextEditingController _quizTitleController = TextEditingController();
  final TextEditingController _quizDescriptionController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _attemptsController = TextEditingController();

  String _selectedCourseId = '';
  List<Map<String, dynamic>> _myCourses = [];
  final List<QuizQuestion> _questions = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('formateurId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _myCourses = coursesSnapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'title': doc.data()['title'] as String? ?? 'Sans titre',
                },
              )
              .toList();
          if (_myCourses.isNotEmpty) {
            _selectedCourseId = _myCourses.first['id'] ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des cours: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestion des Quiz'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Créer Quiz'),
            Tab(icon: Icon(Icons.quiz), text: 'Mes Quiz'),
            Tab(icon: Icon(Icons.analytics), text: 'Résultats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateQuizTab(),
          _buildMyQuizTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  Widget _buildCreateQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _quizFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            const Card(
              color: Colors.deepPurple,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.quiz, color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Text(
                      'Créer un nouveau quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Informations générales du quiz
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Informations générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quizTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre du quiz',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) => val!.isEmpty ? 'Titre requis' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _quizDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCourseId.isEmpty || _myCourses.isEmpty
                          ? null
                          : _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Cours associé',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: _myCourses.isEmpty
                          ? []
                          : _myCourses
                                .map(
                                  (course) => DropdownMenuItem<String>(
                                    value: course['id'] as String,
                                    child: Text(course['title'] as String),
                                  ),
                                )
                                .toList(),
                      onChanged: (val) {
                        if (mounted) {
                          setState(() => _selectedCourseId = val ?? '');
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Sélectionnez un cours' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Durée (minutes)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Durée requise' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _attemptsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nb tentatives',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.repeat),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Nombre requis' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Questions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '❓ Questions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_questions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.quiz, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucune question ajoutée',
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
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          return _buildQuestionCard(index);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _previewQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Prévisualiser'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _saveQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCreating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Créer Quiz'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];

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
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      if (mounted) {
                        setState(() => _questions.removeAt(index));
                      }
                    } else if (value == 'edit') {
                      _editQuestion(index);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.questionText, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: question.options.asMap().entries.map((entry) {
                int optionIndex = entry.key;
                String option = entry.value;
                bool isCorrect = optionIndex == question.correctAnswerIndex;

                return Chip(
                  backgroundColor: isCorrect
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  label: Text(
                    option,
                    style: TextStyle(
                      color: isCorrect ? Colors.green.shade800 : Colors.black87,
                      fontWeight: isCorrect
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  avatar: isCorrect
                      ? const Icon(Icons.check, color: Colors.green, size: 16)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQuizTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where(
            'formateurId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
          )
          .orderBy('createdAt', descending: true)
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
                Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun quiz créé',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Créez votre premier quiz !',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final quizzes = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            final data = quiz.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.quiz, color: Colors.white),
                ),
                title: Text(
                  data['title'] ?? 'Quiz sans titre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? ''),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${data['duration']} min',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.quiz, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${(data['questions'] as List?)?.length ?? 0} questions',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
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
                          Text('Voir résultats'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 8),
                          Text('Dupliquer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleQuizAction(value.toString(), quiz.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where(
            'formateurId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
          )
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
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun résultat disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final attempts = snapshot.data!.docs;
        final groupedAttempts = _groupAttemptsByQuiz(attempts);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedAttempts.length,
          itemBuilder: (context, index) {
            final quizTitle = groupedAttempts.keys.elementAt(index);
            final quizAttempts = groupedAttempts[quizTitle]!;
            final avgScore =
                quizAttempts
                    .map(
                      (a) => (a.data() as Map<String, dynamic>)['score'] ?? 0,
                    )
                    .reduce((a, b) => a + b) /
                quizAttempts.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(avgScore.toInt()),
                  child: Text(
                    '${avgScore.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  quizTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${quizAttempts.length} tentatives • Moyenne: ${avgScore.toStringAsFixed(1)}%',
                ),
                children: quizAttempts.map((attempt) {
                  final data = attempt.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: _getScoreColor(data['score'] ?? 0),
                      child: Text(
                        '${data['score'] ?? 0}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(data['studentName'] ?? 'Étudiant inconnu'),
                    subtitle: Text(_formatDate(data['submittedAt'])),
                    trailing: ElevatedButton(
                      onPressed: () => _viewDetailedResult(attempt.id, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Détails'),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        onSave: (question) {
          if (mounted) {
            setState(() => _questions.add(question));
          }
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        existingQuestion: _questions[index],
        onSave: (question) {
          if (mounted) {
            setState(() => _questions[index] = question);
          }
        },
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_quizFormKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez au moins une question')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isCreating = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String selectedCourseTitle = 'Sans cours';
      if (_myCourses.isNotEmpty && _selectedCourseId.isNotEmpty) {
        selectedCourseTitle =
            _myCourses.firstWhere(
              (course) => course['id'] == _selectedCourseId,
              orElse: () => {'title': 'Sans titre'},
            )['title'] ??
            'Sans titre';
      }

      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': _quizTitleController.text.trim(),
        'description': _quizDescriptionController.text.trim(),
        'course': selectedCourseTitle,
        'courseId': _selectedCourseId,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'maxAttempts': int.tryParse(_attemptsController.text) ?? 1,
        'formateurId': user.uid,
        'questions': _questions.map((q) => q.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (mounted) {
        // Réinitialiser le formulaire
        _quizTitleController.clear();
        _quizDescriptionController.clear();
        _durationController.clear();
        _attemptsController.clear();
        setState(() {
          _questions.clear();
          if (_myCourses.isNotEmpty)
            _selectedCourseId = _myCourses.first['id'] ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz créé avec succès ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Changer vers l'onglet "Mes Quiz"
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _previewQuiz() {
    if (_questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoutez au moins une question pour prévisualiser'),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _quizTitleController.text.isEmpty
              ? 'Prévisualisation'
              : _quizTitleController.text,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(question.questionText),
                      const SizedBox(height: 8),
                      ...question.options.asMap().entries.map((entry) {
                        bool isCorrect =
                            entry.key == question.correctAnswerIndex;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              if (isCorrect)
                                const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.value)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
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

  void _handleQuizAction(
    String action,
    String quizId,
    Map<String, dynamic> quizData,
  ) {
    switch (action) {
      case 'view':
        if (mounted) {
          _tabController.animateTo(2);
        }
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité d\'édition à venir')),
        );
        break;
      case 'duplicate':
        _duplicateQuiz(quizData);
        break;
      case 'delete':
        _deleteQuiz(quizId);
        break;
    }
  }

  void _viewQuizResults(String quizId, Map<String, dynamic> quizData) {
    if (mounted) {
      _tabController.animateTo(2);
    }
  }

  Future<void> _duplicateQuiz(Map<String, dynamic> quizData) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final duplicatedData = Map<String, dynamic>.from(quizData);
      duplicatedData['title'] = '${duplicatedData['title']} (Copie)';
      duplicatedData['formateurId'] = user.uid;
      duplicatedData['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('quizzes')
          .add(duplicatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz dupliqué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce quiz ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewDetailedResult(String attemptId, Map<String, dynamic> attemptData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultat de ${attemptData['studentName']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: ${attemptData['score']}%'),
              Text('Date: ${_formatDate(attemptData['submittedAt'])}'),
              Text('Temps passé: ${attemptData['timeSpent']} minutes'),
              const SizedBox(height: 16),
              const Text(
                'Réponses:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              // Ici, vous pouvez ajouter plus de détails sur les réponses
            ],
          ),
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

  Map<String, List<QueryDocumentSnapshot>> _groupAttemptsByQuiz(
    List<QueryDocumentSnapshot> attempts,
  ) {
    Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var attempt in attempts) {
      final data = attempt.data() as Map<String, dynamic>;
      final quizTitle = data['quizTitle'] ?? 'Quiz sans titre';

      if (!grouped.containsKey(quizTitle)) {
        grouped[quizTitle] = [];
      }
      grouped[quizTitle]!.add(attempt);
    }

    return grouped;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    }
    return 'N/A';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quizTitleController.dispose();
    _quizDescriptionController.dispose();
    _durationController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }
}

// Classe pour représenter une question de quiz
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

// Dialog pour créer/éditer une question
class _QuestionDialog extends StatefulWidget {
  final QuizQuestion? existingQuestion;
  final Function(QuizQuestion) onSave;

  const _QuestionDialog({required this.onSave, this.existingQuestion});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  int _correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();

    _questionController = TextEditingController(
      text: widget.existingQuestion?.questionText ?? '',
    );
    _explanationController = TextEditingController(
      text: widget.existingQuestion?.explanation ?? '',
    );

    if (widget.existingQuestion != null) {
      _optionControllers = widget.existingQuestion!.options
          .map((option) => TextEditingController(text: option))
          .toList();
      _correctAnswerIndex = widget.existingQuestion!.correctAnswerIndex;
    } else {
      _optionControllers = List.generate(4, (_) => TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingQuestion != null
            ? 'Modifier Question'
            : 'Nouvelle Question',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              const Text(
                'Options de réponse:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ..._optionControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctAnswerIndex,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _correctAnswerIndex = value!);
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              TextField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'Explication (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La question est requise')));
      return;
    }

    final options = _optionControllers.map((c) => c.text.trim()).toList();
    if (options.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les options sont requises')),
      );
      return;
    }

    final question = QuizQuestion(
      questionText: _questionController.text.trim(),
      options: options,
      correctAnswerIndex: _correctAnswerIndex,
      explanation: _explanationController.text.trim(),
    );

    widget.onSave(question);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

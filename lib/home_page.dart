import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'student_courses_page.dart';
import 'student_quiz_page.dart';
import 'student_stats_page.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String userRole;

  const HomePage({super.key, required this.userName, required this.userRole});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isPremium = false;

  // Données du dashboard
  Map<String, dynamic> _dashboardData = {
    'coursesCount': 0,
    'completedQuizzes': 0,
    'averageScore': 0,
    'totalProgress': 0,
  };
  bool _isLoadingDashboard = true;
  List<Map<String, dynamic>> _recentCourses = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Récupérer les inscriptions de l'étudiant
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: user.uid)
          .get();

      // Récupérer les tentatives de quiz
      final quizAttemptsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: user.uid)
          .get();

      // Calculer les statistiques
      int coursesCount = enrollmentsSnapshot.docs.length;
      int completedQuizzes = quizAttemptsSnapshot.docs.length;

      double totalProgress = 0;
      if (enrollmentsSnapshot.docs.isNotEmpty) {
        for (var doc in enrollmentsSnapshot.docs) {
          final data = doc.data();
          totalProgress += (data['progress'] ?? 0);
        }
        totalProgress = totalProgress / enrollmentsSnapshot.docs.length;
      }

      double averageScore = 0;
      if (quizAttemptsSnapshot.docs.isNotEmpty) {
        for (var doc in quizAttemptsSnapshot.docs) {
          final data = doc.data();
          averageScore += (data['score'] ?? 0);
        }
        averageScore = averageScore / quizAttemptsSnapshot.docs.length;
      }

      // Récupérer les cours récents
      List<Map<String, dynamic>> recentCourses = [];
      for (var enrollment in enrollmentsSnapshot.docs.take(3)) {
        final data = enrollment.data();
        recentCourses.add({
          'title': data['courseTitle'] ?? 'Cours',
          'progress': data['progress'] ?? 0,
          'isCompleted': data['isCompleted'] ?? false,
        });
      }

      setState(() {
        _dashboardData = {
          'coursesCount': coursesCount,
          'completedQuizzes': completedQuizzes,
          'averageScore': averageScore.round(),
          'totalProgress': totalProgress.round(),
        };
        _recentCourses = recentCourses;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      setState(() => _isLoadingDashboard = false);
      print('Erreur lors du chargement des données: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("EduBot"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: _isLoadingDashboard
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      _buildHeader(),
                      const SizedBox(height: 16),

                      // --- STATISTIQUES RAPIDES ---
                      _buildQuickStats(),
                      const SizedBox(height: 20),

                      // --- CARROUSEL ---
                      _buildCarousel(),
                      const SizedBox(height: 20),

                      // --- COURS RÉCENTS ---
                      _buildRecentCourses(),
                      const SizedBox(height: 20),

                      // --- FILIÈRES (Premium/Gratuit) ---
                      _buildCategories(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'E',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Salut, ${widget.userName}! 👋",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Prêt pour une aventure ?",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!_isPremium)
          ElevatedButton(
            onPressed: () => _showPaymentDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Premium"),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Aperçu de votre progression",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Cours",
                  "${_dashboardData['coursesCount']}",
                  Icons.book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Quiz",
                  "${_dashboardData['completedQuizzes']}",
                  Icons.quiz,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Moyenne",
                  "${_dashboardData['averageScore']}%",
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Progression",
                  "${_dashboardData['totalProgress']}%",
                  Icons.analytics,
                  Colors.orange,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
      ),
      items:
          [
            'assets/images/student.png',
            'assets/images/student2.png',
            'assets/images/student3.png',
          ].map((imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.deepPurple.withOpacity(0.1),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.deepPurple,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildRecentCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📚 Cours récents :",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_recentCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Aucun cours suivi pour le moment.\nInscrivez-vous à votre premier cours !",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._recentCourses.map(
            (course) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: course['isCompleted']
                      ? Colors.green
                      : Colors.orange,
                  child: Icon(
                    course['isCompleted'] ? Icons.check : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                title: Text(course['title']),
                subtitle: LinearProgressIndicator(
                  value: course['progress'] / 100.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    course['isCompleted'] ? Colors.green : Colors.orange,
                  ),
                ),
                trailing: Text("${course['progress']}%"),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🎓 Filières :",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_isPremium)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategory("Informatique", Icons.computer, Colors.blue),
                _buildCategory(
                  "Ressources Humaines",
                  Icons.group,
                  Colors.orange,
                ),
                _buildCategory(
                  "Sciences de la Vie",
                  Icons.biotech,
                  Colors.green,
                ),
                _buildCategory(
                  "Comptabilité",
                  Icons.account_balance,
                  Colors.purple,
                ),
                _buildCategory("Mathématiques", Icons.calculate, Colors.teal),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Accès limité en mode gratuit !",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showPaymentDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Passer en mode Premium"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategory(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDashboardButton(
              context,
              "Accueil",
              Icons.home,
              Colors.deepPurple,
              0,
            ),
            _buildDashboardButton(
              context,
              "Mes Cours",
              Icons.book,
              Colors.blue,
              1,
            ),
            _buildDashboardButton(
              context,
              "Quiz",
              Icons.quiz,
              Colors.orange,
              2,
            ),
            _buildDashboardButton(
              context,
              "Chat EduBot",
              Icons.smart_toy,
              Colors.green,
              3,
            ),
            _buildDashboardButton(
              context,
              "Mon Profil",
              Icons.person,
              Colors.purple,
              4,
            ),
            _buildDashboardButton(
              context,
              "Statistiques",
              Icons.analytics,
              Colors.red,
              5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);

        switch (index) {
          case 0: // Accueil - déjà là
            break;
          case 1: // Mes Cours
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentCoursesPage(),
              ),
            );
            break;
          case 2: // Quiz
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentQuizPage()),
            );
            break;
          case 3: // Chat EduBot
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "💬 Chatbot en développement - Bientôt disponible !",
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 4: // Profil
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userName: widget.userName),
              ),
            );
            break;
          case 5: // Statistiques
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StudentStatsPage()),
            );
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Passer en mode Premium"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisissez un plan de paiement :"),
            const SizedBox(height: 10),
            _buildPaymentOption("500 FCFA / mois"),
            _buildPaymentOption("1000 FCFA / 3 mois"),
            _buildPaymentOption("2000 FCFA / 5 mois"),
            const SizedBox(height: 10),
            const Text("Méthodes de paiement : Mobile Money ou Orange Money"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isPremium = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Paiement réussi ! Mode Premium activé. 🎉"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Payer"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String option) {
    return ListTile(
      title: Text(option),
      trailing: const Icon(Icons.payment),
      onTap: () {
        // Logique de sélection de l'option
      },
    );
  }
}

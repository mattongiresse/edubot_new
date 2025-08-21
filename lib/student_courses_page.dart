import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'formateur_courses_page.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  String _selectedCategory = 'Tous';
  final List<String> _categories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Langues',
    'Histoire',
    'Économie',
  ];

  Future<void> _openPdf(String url, String title) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le PDF')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _enrollInCourse(String courseId, String courseTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Vérifier si déjà inscrit
      final existingEnrollment = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous êtes déjà inscrit à ce cours !')),
        );
        return;
      }

      // Récupérer les infos étudiant
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final studentName =
          '${userDoc.data()?['prenom']} ${userDoc.data()?['nom']}';

      // Créer l'inscription
      await FirebaseFirestore.instance.collection('enrollments').add({
        'studentId': user.uid,
        'studentName': studentName,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'isCompleted': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inscription réussie ! 🎉')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'inscription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Cours'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 🎯 Filtres par catégorie
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 📚 Liste des cours
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'Tous'
                  ? FirebaseFirestore.instance
                        .collection('courses')
                        .where('isActive', isEqualTo: true)
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('courses')
                        .where('isActive', isEqualTo: true)
                        .where('category', isEqualTo: _selectedCategory)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun cours disponible',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les formateurs n\'ont pas encore ajouté de cours.',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final courses = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final data = course.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête du cours
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade400,
                                  Colors.deepPurple.shade600,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Sans titre',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Par ${data['formateurNom'] ?? 'Formateur'}',
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
                                    data['category'] ?? '',
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

                          // Contenu du cours
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['description'] ?? 'Pas de description',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Actions
                                Row(
                                  children: [
                                    // Bouton PDF
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openPdf(
                                          data['pdfUrl'] ?? '',
                                          data['title'] ?? 'Cours',
                                        ),
                                        icon: const Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                        ),
                                        label: const Text('Ouvrir PDF'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade50,
                                          foregroundColor: Colors.red,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(
                                              color: Colors.red.shade200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Bouton inscription
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _enrollInCourse(
                                          course.id,
                                          data['title'] ?? 'Cours',
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('S\'inscrire'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
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
            ),
          ),

          // 📋 Section "Mes cours suivis"
          Container(
            margin: const EdgeInsets.all(16),
            child: ExpansionTile(
              leading: const Icon(Icons.bookmark, color: Colors.deepPurple),
              title: const Text(
                'Mes cours suivis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where(
                        'studentId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun cours suivi pour le moment'),
                      );
                    }

                    final enrollments = snapshot.data!.docs;

                    return Column(
                      children: enrollments.map((enrollment) {
                        final data = enrollment.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: Text(data['courseTitle'] ?? ''),
                          subtitle: Text('Progression: ${data['progress']}%'),
                          trailing: LinearProgressIndicator(
                            value: (data['progress'] ?? 0) / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

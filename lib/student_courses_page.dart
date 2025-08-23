import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course_service_page.dart'; // Importez le service créé précédemment

class StudentCoursesPageImproved extends StatefulWidget {
  const StudentCoursesPageImproved({super.key});

  @override
  State<StudentCoursesPageImproved> createState() =>
      _StudentCoursesPageImprovedState();
}

class _StudentCoursesPageImprovedState extends State<StudentCoursesPageImproved>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Langues',
    'Histoire',
    'Économie',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Cours',
          style: TextStyle(fontSize: 18),
        ), // Réduit la taille du titre
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1, // Réduit de 2 à 1
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontSize: 12,
          ), // Réduit la taille des labels
          tabs: const [
            Tab(text: 'Tous les Cours', icon: Icon(Icons.school, size: 18)),
            Tab(text: 'Mes Inscriptions', icon: Icon(Icons.bookmark, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllCoursesTab(), _buildMyCoursesTab()],
      ),
    );
  }

  Widget _buildAllCoursesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Barre de recherche et filtres (minimisés)
          Container(
            padding: const EdgeInsets.all(4), // Réduit de 6 à 4
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 2), // Réduit de 4 à 2

                SizedBox(
                  height: 20, // Réduit de 28 à 20
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Container(
                        margin: const EdgeInsets.only(
                          right: 2,
                        ), // Réduit de 4 à 2
                        child: FilterChip(
                          label: Text(
                            category,
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.deepPurple.withOpacity(0.2),
                          checkmarkColor: Colors.deepPurple,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des cours avec Expanded
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedCategory == 'Tous'
          ? FirebaseFirestore.instance
                .collection('courses')
                .where('isActive', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots()
          : FirebaseFirestore.instance
                .collection('courses')
                .where('category', isEqualTo: _selectedCategory)
                .where('isActive', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucun cours disponible');
        }

        final courses = snapshot.data!.docs.where((course) {
          if (_searchQuery.isEmpty) return true;
          final data = course.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '')
              .toString()
              .toLowerCase();
          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        }).toList();

        if (courses.isEmpty) {
          return _buildEmptyState('Aucun cours trouvé pour "$_searchQuery"');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(4), // Réduit de 6 à 4
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final data = course.data() as Map<String, dynamic>;
            return _buildCourseCard(course.id, data);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> courseData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4), // Réduit de 6 à 4
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(8), // Réduit de 10 à 8
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Réduit de 3 à 2
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          courseData['category'] ?? '',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 14),
                          SizedBox(width: 4),
                          Text('Voir le cours'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 14),
                          SizedBox(width: 4),
                          Text('Télécharger PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'enroll',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14),
                          SizedBox(width: 4),
                          Text('S\'inscrire'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleCourseAction(value, courseId, courseData),
                ),
              ],
            ),
            const SizedBox(height: 4), // Réduit de 6 à 4
            Text(
              courseData['description'] ?? 'Aucune description',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    courseData['formateurNom'] ?? 'Formateur inconnu',
                    style: TextStyle(color: Colors.grey[600], fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.file_present, size: 12, color: Colors.red[600]),
                const SizedBox(width: 2),
                Text(
                  _formatFileSize(courseData['fileSize'] ?? 0),
                  style: TextStyle(color: Colors.grey[600], fontSize: 8),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatChip(
                  Icons.people,
                  '${courseData['enrollmentCount'] ?? 0} inscrits',
                  Colors.blue,
                ),
                _buildStatChip(
                  Icons.download,
                  '${courseData['downloadCount'] ?? 0} téléchargements',
                  Colors.green,
                ),
                _buildStatChip(
                  Icons.thumb_up,
                  '${courseData['likes'] ?? 0} likes',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _enrollInCourse(courseId, courseData),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('S\'inscrire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 3), // Réduit de 4 à 3
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPdf(courseData['pdfUrl']),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Voir PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 1,
      ), // Réduit de 5/2 à 4/1
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 1), // Réduit de 2 à 1
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 6, // Réduit de 7 à 6
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text(
          'Veuillez vous connecter pour voir vos cours',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .orderBy('enrolledAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Vous n\'êtes inscrit à aucun cours');
        }

        final enrollments = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(4), // Réduit de 6 à 4
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            final data = enrollment.data() as Map<String, dynamic>;
            return _buildEnrollmentCard(data);
          },
        );
      },
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollmentData) {
    final progress = enrollmentData['progress'] ?? 0;
    final isCompleted = enrollmentData['isCompleted'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 4), // Réduit de 6 à 4
      child: ListTile(
        leading: CircleAvatar(
          radius: 10, // Réduit de 12 à 10
          backgroundColor: isCompleted ? Colors.green : Colors.orange,
          child: Icon(
            isCompleted ? Icons.check : Icons.play_arrow,
            size: 12, // Réduit
            color: Colors.white,
          ),
        ),
        title: Text(
          enrollmentData['courseTitle'] ?? 'Cours sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2), // Réduit de 4 à 2
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Progression: $progress%',
              style: const TextStyle(fontSize: 8),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 16),
          onPressed: () {
            _openEnrolledCourse(enrollmentData['courseId']);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 40,
            color: Colors.grey[400],
          ), // Réduit de 50 à 40
          const SizedBox(height: 8), // Réduit de 10 à 8
          Text(
            message,
            style: TextStyle(
              fontSize: 12, // Réduit de 14 à 12
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // Réduit de 5 à 4
          Text(
            'Explorez notre catalogue de cours !',
            style: TextStyle(color: Colors.grey[500], fontSize: 8), // Réduit
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return "${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}";
  }

  void _handleCourseAction(
    String action,
    String courseId,
    Map<String, dynamic> courseData,
  ) {
    switch (action) {
      case 'view':
        _viewPdf(courseData['pdfUrl']);
        break;
      case 'download':
        _downloadPdf(courseData['pdfUrl'], courseId);
        break;
      case 'enroll':
        _enrollInCourse(courseId, courseData);
        break;
    }
  }

  Future<void> _viewPdf(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      _showSnackBar('URL du PDF non disponible', isError: true);
      return;
    }

    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Impossible d\'ouvrir le PDF', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture du PDF', isError: true);
    }
  }

  Future<void> _downloadPdf(String? pdfUrl, String courseId) async {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      _showSnackBar('URL du PDF non disponible', isError: true);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'downloadCount': FieldValue.increment(1)});

      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('Téléchargement démarré');
      } else {
        _showSnackBar('Impossible de télécharger le PDF', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors du téléchargement', isError: true);
    }
  }

  Future<void> _enrollInCourse(
    String courseId,
    Map<String, dynamic> courseData,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(
        'Veuillez vous connecter pour vous inscrire',
        isError: true,
      );
      return;
    }

    try {
      final existingEnrollment = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();

      if (existingEnrollment.docs.isNotEmpty) {
        _showSnackBar('Vous êtes déjà inscrit à ce cours', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('enrollments').add({
        'studentId': userId,
        'courseId': courseId,
        'courseTitle': courseData['title'],
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0,
        'isCompleted': false,
        'lastAccessed': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'enrollmentCount': FieldValue.increment(1)});

      _showSnackBar('Inscription réussie ! 🎉');
      _tabController.animateTo(1);
    } catch (e) {
      _showSnackBar('Erreur lors de l\'inscription', isError: true);
    }
  }

  Future<void> _openEnrolledCourse(String courseId) async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (courseDoc.exists) {
        final courseData = courseDoc.data()!;
        _viewPdf(courseData['pdfUrl']);

        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final enrollmentQuery = await FirebaseFirestore.instance
              .collection('enrollments')
              .where('studentId', isEqualTo: userId)
              .where('courseId', isEqualTo: courseId)
              .get();

          if (enrollmentQuery.docs.isNotEmpty) {
            await enrollmentQuery.docs.first.reference.update({
              'lastAccessed': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ouverture du cours', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }
}

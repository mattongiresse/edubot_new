import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

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
    _checkPdfPaths();
    _fixPdfPaths();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Script pour vérifier les pdfPath
  Future<void> _checkPdfPaths() async {
    final courses = await FirebaseFirestore.instance
        .collection('courses')
        .get();
    for (var doc in courses.docs) {
      final pdfPath = doc['pdfPath'] ?? '';
      if (pdfPath.isNotEmpty) {
        try {
          final cleanedPdfPath = _cleanPdfPath(pdfPath);
          final url = Supabase.instance.client.storage
              .from('course-files')
              .getPublicUrl(cleanedPdfPath);
          final response = await http.head(Uri.parse(url));
          if (response.statusCode == 200) {
            print('Fichier valide : $pdfPath pour ${doc.id}');
          } else {
            print(
              'Fichier invalide pour ${doc.id} : $pdfPath (HTTP ${response.statusCode})',
            );
          }
        } catch (e) {
          print('Erreur pour ${doc.id} : $pdfPath ($e)');
        }
      }
    }
  }

  // Script pour corriger les pdfPath dans Firestore
  Future<void> _fixPdfPaths() async {
    const prefix = 'storage/v1/object/public/course-files/';
    final courses = await FirebaseFirestore.instance
        .collection('courses')
        .get();
    for (var doc in courses.docs) {
      final pdfPath = doc['pdfPath'] ?? '';
      if (pdfPath.isNotEmpty && pdfPath.startsWith(prefix)) {
        final cleanedPdfPath = pdfPath.substring(prefix.length);
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(doc.id)
            .update({'pdfPath': cleanedPdfPath});
        print('Corrigé pdfPath pour ${doc.id} : $pdfPath -> $cleanedPdfPath');
      }
    }
  }

  // Nettoyer le pdfPath
  String _cleanPdfPath(String pdfPath) {
    const prefix = 'storage/v1/object/public/course-files/';
    if (pdfPath.startsWith(prefix)) {
      return pdfPath.substring(prefix.length);
    }
    return pdfPath.trim();
  }

  // Nouvelle méthode pour liker un cours
  Future<void> _likeCourse(String courseId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(
        'Veuillez vous connecter pour liker un cours',
        isError: true,
      );
      return;
    }

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('likes')
          .doc(userId)
          .get();

      if (likeDoc.exists) {
        _showSnackBar('Vous avez déjà liké ce cours', isError: true);
        return;
      }

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('likes')
          .doc(userId)
          .set({'likedAt': FieldValue.serverTimestamp()});

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'likeCount': FieldValue.increment(1)});

      _showSnackBar('Cours liké ! 👍');
    } catch (e) {
      _showSnackBar('Erreur lors du like: $e', isError: true);
    }
  }

  // Nouvelle méthode pour télécharger un cours
  Future<void> _downloadCourse(String? pdfPath, String courseId) async {
    if (pdfPath == null || pdfPath.isEmpty) {
      _showSnackBar('Chemin du PDF non disponible', isError: true);
      return;
    }

    try {
      final cleanedPdfPath = _cleanPdfPath(pdfPath);
      final supabase = Supabase.instance.client;
      final pdfUrl = supabase.storage
          .from('course-files')
          .getPublicUrl(cleanedPdfPath);
      print(
        'Tentative de téléchargement du PDF avec pdfPath: $cleanedPdfPath, url: $pdfUrl',
      );

      final response = await http.head(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Fichier non trouvé dans Supabase (HTTP ${response.statusCode})',
        );
      }

      final downloadResponse = await http.get(Uri.parse(pdfUrl));
      final directory = await getApplicationDocumentsDirectory();
      final fileName = cleanedPdfPath.split('/').last;
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(downloadResponse.bodyBytes);

      _showSnackBar(
        'Cours téléchargé avec succès dans ${directory.path}/$fileName !',
      );
    } catch (e) {
      _showSnackBar('Erreur lors du téléchargement: $e', isError: true);
      print('Erreur téléchargement : $e (pdfPath: $pdfPath)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Cours', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontSize: 12),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
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
        Expanded(child: _buildCoursesList()),
      ],
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

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucun cours disponible');
        }

        final courses = snapshot.data!.docs.where((course) {
          if (_searchQuery.isEmpty) return true;
          final data = course.data() as Map<String, dynamic>?;
          if (data == null) return false;

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
          padding: const EdgeInsets.all(8),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final data = course.data() as Map<String, dynamic>?;
            if (data == null) return const SizedBox.shrink();

            return _buildCourseCard(course.id, data);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> courseData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        courseData['title'] ?? 'Cours sans titre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseData['description'] ?? 'Aucune description',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catégorie: ${courseData['category'] ?? 'Non spécifiée'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Likes: ${courseData['likeCount'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, size: 20),
                      onPressed: () =>
                          _viewPdf(courseData['pdfPath'], courseId: courseId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 20),
                      onPressed: () => _likeCourse(courseId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () =>
                          _downloadCourse(courseData['pdfPath'], courseId),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Créé le: ${courseData['createdAt']?.toDate().toString().split(' ')[0] ?? 'N/A'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                ElevatedButton(
                  onPressed: () => _enrollInCourse(courseId, courseData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('S\'inscrire'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucun cours inscrit');
        }

        final enrollments = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            final data = enrollment.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  data['courseTitle'] ?? 'Cours sans titre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progression: ${data['progress'] ?? 0}%'),
                    Text(
                      'Dernier accès: ${data['lastAccessed']?.toDate().toString().split(' ')[0] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 20),
                      onPressed: () => _likeCourse(data['courseId']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: () =>
                          _downloadCourse(data['pdfPath'], data['courseId']),
                    ),
                    ElevatedButton(
                      onPressed: () => _openEnrolledCourse(data['courseId']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Ouvrir'),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPdf(String? pdfPath, {String? courseId}) async {
    if (pdfPath == null || pdfPath.isEmpty) {
      _showSnackBar('Chemin du PDF non disponible', isError: true);
      return;
    }

    try {
      // Nettoyer le pdfPath
      final cleanedPdfPath = _cleanPdfPath(pdfPath);
      print(
        'pdfPath brut: $pdfPath, pdfPath encodé: ${Uri.encodeComponent(cleanedPdfPath)}',
      );

      // Utiliser Supabase pour obtenir l'URL publique
      final supabase = Supabase.instance.client;
      final pdfUrl = supabase.storage
          .from('course-files')
          .getPublicUrl(cleanedPdfPath);
      print(
        'Tentative d\'ouverture du PDF avec pdfPath: $cleanedPdfPath, url: $pdfUrl',
      );

      // Vérifier si le fichier existe
      final response = await http.head(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Fichier non trouvé dans Supabase (HTTP ${response.statusCode})',
        );
      }

      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Visionneuse PDF')),
              body: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(uri),
              ),
            ),
          ),
        );
      }

      if (courseId != null) {
        await _initializeCourseFields(courseId);
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .update({'viewCount': FieldValue.increment(1)});
      }
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'ouverture du PDF : Fichier non trouvé ou chemin incorrect',
        isError: true,
      );
      print('Erreur PDF : $e (pdfPath: $pdfPath)');
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
        'pdfPath': courseData['pdfPath'], // Ajouté pour stocker pdfPath
      });

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'enrollmentCount': FieldValue.increment(1)});

      _showSnackBar('Inscription réussie ! 🎉');
      _tabController.animateTo(1);
    } catch (e) {
      _showSnackBar('Erreur lors de l\'inscription: $e', isError: true);
    }
  }

  Future<void> _openEnrolledCourse(String? courseId) async {
    if (courseId == null) {
      _showSnackBar('ID du cours non disponible', isError: true);
      return;
    }

    String? pdfPath;
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (courseDoc.exists && courseDoc.data() != null) {
        final courseData = courseDoc.data()!;
        pdfPath = courseData['pdfPath'] ?? '';
        if (pdfPath!.isEmpty) {
          _showSnackBar('Aucun PDF associé à ce cours', isError: true);
          return;
        }

        // Nettoyer le pdfPath
        final cleanedPdfPath = _cleanPdfPath(pdfPath!);
        print(
          'pdfPath brut: $pdfPath, pdfPath encodé: ${Uri.encodeComponent(cleanedPdfPath)}',
        );

        // Utiliser Supabase pour obtenir l'URL publique
        final supabase = Supabase.instance.client;
        final pdfUrl = supabase.storage
            .from('course-files')
            .getPublicUrl(cleanedPdfPath);
        print(
          'Tentative d\'ouverture du PDF avec pdfPath: $cleanedPdfPath, url: $pdfUrl',
        );

        // Vérifier si le fichier existe
        final response = await http.head(Uri.parse(pdfUrl));
        if (response.statusCode != 200) {
          throw Exception(
            'Fichier non trouvé dans Supabase (HTTP ${response.statusCode})',
          );
        }

        // Télécharger le PDF localement pour PDFView
        final downloadResponse = await http.get(Uri.parse(pdfUrl));
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_$courseId.pdf');
        await file.writeAsBytes(downloadResponse.bodyBytes);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PDFViewerPage(filePath: file.path, courseId: courseId),
          ),
        );

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

        // Incrémente viewCount
        await _initializeCourseFields(courseId);
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .update({'viewCount': FieldValue.increment(1)});
      } else {
        _showSnackBar('Cours introuvable', isError: true);
      }
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'ouverture du cours: Fichier non trouvé ou chemin incorrect',
        isError: true,
      );
      print(
        'Erreur ouverture cours : $e (pdfPath: ${pdfPath ?? 'non défini'})',
      );
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

  Future<void> _initializeCourseFields(String courseId) async {
    final docRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId);
    await docRef.set({
      'viewCount': 0,
      'enrollmentCount': 0,
      'likeCount': 0, // Ajouté pour initialiser likeCount
    }, SetOptions(merge: true));
  }
}

class PDFViewerPage extends StatefulWidget {
  final String filePath;
  final String courseId;

  const PDFViewerPage({
    required this.filePath,
    required this.courseId,
    super.key,
  });

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  int? pages = 0;
  int? currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecture du PDF')),
      body: PDFView(
        filePath: widget.filePath,
        onRender: (_pages) {
          setState(() {
            pages = _pages;
          });
        },
        onPageChanged: (page, total) {
          setState(() {
            currentPage = page;
          });
          final progress = ((page! / total!) * 100).toInt();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            FirebaseFirestore.instance
                .collection('enrollments')
                .where('studentId', isEqualTo: userId)
                .where('courseId', isEqualTo: widget.courseId)
                .get()
                .then((query) {
                  if (query.docs.isNotEmpty) {
                    query.docs.first.reference.update({'progress': progress});
                  }
                });
          }
        },
      ),
    );
  }
}

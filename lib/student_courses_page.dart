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

    // Test de connexion Supabase (à supprimer en production)
    Future.delayed(Duration(seconds: 2), () {
      _testSupabaseConnection();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Méthode de debug pour analyser les données d'un cours
  Future<void> _debugCourseData(String courseId) async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (courseDoc.exists) {
        final data = courseDoc.data();
        print('=== DEBUG COURSE DATA ===');
        print('Course ID: $courseId');
        print('Course data: $data');
        print('pdfPath value: ${data?['pdfPath']}');
        print('pdfPath type: ${data?['pdfPath'].runtimeType}');
        print('Available keys: ${data?.keys.toList()}');
        print('========================');
      } else {
        print('Course document does not exist');
      }
    } catch (e) {
      print('Error debugging course data: $e');
    }
  }

  // Test de connexion Supabase
  Future<void> _testSupabaseConnection() async {
    try {
      final supabase = Supabase.instance.client;

      // Test de listage des fichiers dans le dossier courses
      final fileList = await supabase.storage
          .from('course-files')
          .list(path: 'courses');
      print('=== SUPABASE CONNECTION TEST ===');
      print('Bucket "course-files" accessible: true');
      print('Number of folders in courses: ${fileList.length}');

      // Lister les fichiers dans chaque dossier utilisateur
      for (var folder in fileList) {
        if (folder.metadata?['isDirectory'] == true || folder.name != null) {
          try {
            final subFiles = await supabase.storage
                .from('course-files')
                .list(path: 'courses/${folder.name}');
            print(
              'Files in courses/${folder.name}: ${subFiles.map((f) => f.name).join(', ')}',
            );

            // Test d'URL sur le premier fichier trouvé
            if (subFiles.isNotEmpty) {
              final testPath = 'courses/${folder.name}/${subFiles.first.name}';
              final testUrl = supabase.storage
                  .from('course-files')
                  .getPublicUrl(testPath);
              print('Test URL: $testUrl');

              final response = await http.head(Uri.parse(testUrl));
              print('Test URL status: ${response.statusCode}');
            }
          } catch (e) {
            print('Error listing files in courses/${folder.name}: $e');
          }
        }
      }
      print('===============================');
    } catch (e) {
      print('Supabase connection error: $e');
    }
  }

  // Corriger les données d'inscription
  Future<void> _fixEnrollmentData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final enrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .get();

      for (var enrollment in enrollments.docs) {
        final data = enrollment.data();
        final courseId = data['courseId'];

        if (courseId != null) {
          // Récupérer les données du cours
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();

          if (courseDoc.exists) {
            final courseData = courseDoc.data()!;
            final pdfPath = courseData['pdfPath'];

            // Mettre à jour l'enrollment avec le pdfPath du cours
            if (pdfPath != null && pdfPath.toString().isNotEmpty) {
              await enrollment.reference.update({'pdfPath': pdfPath});
              print(
                'Updated enrollment ${enrollment.id} with pdfPath: $pdfPath',
              );
            }
          }
        }
      }

      _showSnackBar('Données d\'inscription mises à jour');
    } catch (e) {
      print('Error fixing enrollment data: $e');
    }
  }

  // Script pour vérifier les pdfPath
  Future<void> _checkPdfPaths() async {
    final courses = await FirebaseFirestore.instance
        .collection('courses')
        .get();

    for (var doc in courses.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // On vérifie si le champ "pdfPath" existe et n'est pas vide
      final pdfPath = data.containsKey('pdfPath') && data['pdfPath'] != null
          ? data['pdfPath'] as String
          : '';

      if (pdfPath.isNotEmpty) {
        try {
          final cleanedPdfPath = _cleanPdfPath(pdfPath);
          final url = Supabase.instance.client.storage
              .from('course-files')
              .getPublicUrl(cleanedPdfPath);

          final response = await http.head(Uri.parse(url));
          print('Headers: ${response.headers}');
          print('Reason: ${response.reasonPhrase}');
        } catch (e) {
          print('❌ Erreur pour ${doc.id} : $pdfPath ($e)');
        }
      } else {
        print('ℹ️ Aucun pdfPath défini pour ${doc.id}');
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
      final data = doc.data() as Map<String, dynamic>?;

      final pdfPath = (data != null && data.containsKey('pdfPath'))
          ? data['pdfPath'] as String
          : '';

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

  String _cleanPdfPath(String pdfPath) {
    const prefix = 'storage/v1/object/public/course-files/';
    String cleanedPath = pdfPath.trim();

    // Supprimer le préfixe s'il existe
    if (cleanedPath.startsWith(prefix)) {
      cleanedPath = cleanedPath.substring(prefix.length);
    }

    // Ne pas encoder ici – Supabase gère l'encodage dans l'URL
    // cleanedPath = Uri.encodeComponent(cleanedPath.trim());  // Supprime cette ligne

    // Débogages
    print('Cleaned pdfPath: $cleanedPath (original: $pdfPath)');
    return cleanedPath;
  }

  // Méthode pour construire l'URL Supabase
  String _buildSupabaseUrl(String pdfPath) {
    if (pdfPath.isEmpty) {
      print('Error: pdfPath is empty');
      throw Exception('Chemin du PDF vide');
    }

    final supabase = Supabase.instance.client;
    final cleanedPath = _cleanPdfPath(pdfPath);
    final url = supabase.storage.from('course-files').getPublicUrl(cleanedPath);

    // Débogage
    print('Generated Supabase URL: $url');
    return url;
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

  // Méthode pour télécharger un cours
  Future<void> _downloadCourse(String? pdfPath, String courseId) async {
    if (pdfPath == null || pdfPath.isEmpty) {
      _showSnackBar('Chemin du PDF non disponible', isError: true);
      print('Error: pdfPath is null or empty');
      return;
    }

    try {
      String pdfUrl;

      // Vérifier si c'est déjà une URL complète
      if (pdfPath.startsWith('http')) {
        pdfUrl = pdfPath;
        print('Using direct URL: $pdfUrl');
      } else {
        // Construire l'URL Supabase
        pdfUrl = _buildSupabaseUrl(pdfPath);
      }

      print('Téléchargement du PDF : $pdfUrl');

      final response = await http.head(Uri.parse(pdfUrl));
      print('HTTP HEAD response for $pdfUrl: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception(
          'Fichier non trouvé dans Supabase (HTTP ${response.statusCode})',
        );
      }

      final downloadResponse = await http.get(Uri.parse(pdfUrl));
      final directory = await getApplicationDocumentsDirectory();
      final fileName = Uri.decodeComponent(pdfPath.split('/').last);
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(downloadResponse.bodyBytes);

      _showSnackBar(
        'Cours téléchargé avec succès dans ${directory.path}/$fileName !',
      );
    } catch (e) {
      _showSnackBar(
        'Erreur lors du téléchargement : ${e.toString()}',
        isError: true,
      );
      print('Erreur téléchargement : $e (pdfPath: $pdfPath)');

      // Lister les fichiers dans le bucket pour débogage
      try {
        final supabase = Supabase.instance.client;
        final fileList = await supabase.storage.from('course-files').list();
        print(
          'Fichiers dans le bucket course-files : ${fileList.map((f) => f.name).join(', ')}',
        );
      } catch (listError) {
        print('Erreur lors du listage des fichiers : $listError');
      }
    }
  }

  // Méthode pour voir un PDF
  Future<void> _viewPdf(String? pdfPath, {String? courseId}) async {
    if (pdfPath == null || pdfPath.isEmpty) {
      _showSnackBar('Chemin du PDF non disponible', isError: true);
      print('Error: pdfPath is null or empty');
      return;
    }

    try {
      String pdfUrl;

      // Vérifier si c'est déjà une URL complète
      if (pdfPath.startsWith('http')) {
        pdfUrl = pdfPath;
        print('Using direct URL: $pdfUrl');
      } else {
        // Construire l'URL Supabase
        pdfUrl = _buildSupabaseUrl(pdfPath);
      }

      // Vérifier si le fichier existe
      final response = await http.head(Uri.parse(pdfUrl));
      print('HTTP HEAD response for $pdfUrl: ${response.statusCode}');
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
              appBar: AppBar(
                title: const Text(
                  'Visionneuse PDF',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                backgroundColor: const Color(0xFF6B46C1),
              ),
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
        'Erreur lors de l\'ouverture du PDF : ${e.toString()}',
        isError: true,
      );
      print('Erreur ouverture PDF : $e (pdfPath: $pdfPath)');

      // Lister les fichiers dans le bucket pour débogage
      try {
        final supabase = Supabase.instance.client;
        final fileList = await supabase.storage.from('course-files').list();
        print(
          'Fichiers dans le bucket course-files : ${fileList.map((f) => f.name).join(', ')}',
        );
      } catch (listError) {
        print('Erreur lors du listage des fichiers : $listError');
      }
    }
  }

  // Méthode pour ouvrir un cours inscrit
  Future<void> _openEnrolledCourse(String? courseId) async {
    if (courseId == null) {
      _showSnackBar('ID du cours non disponible', isError: true);
      print('Error: courseId is null');
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

        // Essayer d'abord pdfPath, puis pdfUrl, puis autres champs possibles
        pdfPath =
            courseData['pdfPath'] as String? ??
            courseData['pdfUrl'] as String? ??
            courseData['filePath'] as String? ??
            courseData['fileUrl'] as String? ??
            courseData['documentPath'] as String? ??
            courseData['pdf_path'] as String? ??
            courseData['file_path'] as String? ??
            courseData['document_url'] as String?;

        if (pdfPath == null || pdfPath.isEmpty) {
          _showSnackBar('Aucun PDF associé à ce cours', isError: true);
          print('No PDF path found. Available data: $courseData');
          return;
        }

        print('Raw pdfPath: $pdfPath');

        String pdfUrl;

        // Vérifier si c'est déjà une URL complète
        if (pdfPath.startsWith('http')) {
          pdfUrl = pdfPath;
          print('Using direct URL: $pdfUrl');
        } else {
          // Construire l'URL Supabase
          pdfUrl = _buildSupabaseUrl(pdfPath);
        }

        print('Generated URL: $pdfUrl');

        // Vérifier si le fichier existe
        final response = await http.head(Uri.parse(pdfUrl));
        print('HTTP HEAD response for $pdfUrl: ${response.statusCode}');
        if (response.statusCode != 200) {
          throw Exception(
            'Fichier non trouvé dans Supabase (HTTP ${response.statusCode})',
          );
        }

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

        // Mettre à jour l'accès
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

        await _initializeCourseFields(courseId);
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .update({'viewCount': FieldValue.increment(1)});
      } else {
        _showSnackBar('Cours introuvable', isError: true);
        print('Course document not found for courseId: $courseId');
      }
    } catch (e) {
      _showSnackBar(
        'Erreur lors de l\'ouverture du cours : ${e.toString()}',
        isError: true,
      );
      print(
        'Erreur ouverture cours : $e (pdfPath: ${pdfPath ?? 'non défini'})',
      );

      // Lister les fichiers dans le bucket pour débogage
      try {
        final supabase = Supabase.instance.client;
        final fileList = await supabase.storage.from('course-files').list();
        print(
          'Fichiers dans le bucket course-files : ${fileList.map((f) => f.name).join(', ')}',
        );
      } catch (listError) {
        print('Erreur lors du listage des fichiers : $listError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Cours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B46C1), Color(0xFF4C51BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
          tabs: const [
            Tab(
              text: 'Tous les Cours',
              icon: Icon(Icons.school_outlined, size: 20),
            ),
            Tab(
              text: 'Mes Inscriptions',
              icon: Icon(Icons.bookmark_border, size: 20),
            ),
          ],
          indicator: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 3)),
          ),
          dividerColor: Colors.transparent,
        ),
        // Bouton de debug temporaire
        actions: [
          IconButton(
            onPressed: _fixEnrollmentData,
            icon: Icon(Icons.build, color: Colors.white),
            tooltip: 'Corriger les données',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllCoursesTab(), _buildMyCoursesTab()],
        physics: const BouncingScrollPhysics(),
      ),
      // Bouton de debug temporaire
      floatingActionButton: FloatingActionButton(
        onPressed: _testSupabaseConnection,
        backgroundColor: Color(0xFF6B46C1),
        child: Icon(Icons.bug_report, color: Colors.white),
        tooltip: 'Test Supabase',
      ),
    );
  }

  Widget _buildAllCoursesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un cours...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Inter',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF6B46C1),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: Color(0xFF6B46C1),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B46C1),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: const Color(0xFF6B46C1),
                        backgroundColor: Colors.grey[100],
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          );
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
          padding: const EdgeInsets.all(12),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final data = course.data() as Map<String, dynamic>?;
            if (data == null) return const SizedBox.shrink();

            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: _buildCourseCard(course.id, data),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> courseData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        courseData['description'] ?? 'Aucune description',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Catégorie: ${courseData['category'] ?? 'Non spécifiée'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: Color(0xFF6B46C1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Likes: ${courseData['likeCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 22,
                        color: Color(0xFF6B46C1),
                      ),
                      onPressed: () =>
                          _viewPdf(courseData['pdfPath'], courseId: courseId),
                      tooltip: 'Voir le PDF',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 22,
                        color: Color(0xFF6B46C1),
                      ),
                      onPressed: () => _likeCourse(courseId),
                      tooltip: 'Liker',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download_outlined,
                        size: 22,
                        color: Color(0xFF6B46C1),
                      ),
                      onPressed: () =>
                          _downloadCourse(courseData['pdfPath'], courseId),
                      tooltip: 'Télécharger',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Créé le: ${courseData['createdAt']?.toDate().toString().split(' ')[0] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontFamily: 'Inter',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _enrollInCourse(courseId, courseData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                    elevation: 2,
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
      return const Center(
        child: Text(
          'Veuillez vous connecter',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            color: Colors.grey,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Aucun cours inscrit');
        }

        final enrollments = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            final data = enrollment.data() as Map<String, dynamic>;
            final progress = (data['progress'] ?? 0) as int;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  data['courseTitle'] ?? 'Cours sans titre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 75
                            ? const Color(0xFF38A169)
                            : progress >= 50
                            ? Colors.orange
                            : const Color(0xFFE53E3E),
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Progression: $progress%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'Dernier accès: ${data['lastAccessed']?.toDate().toString().split(' ')[0] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.bug_report,
                        size: 22,
                        color: Colors.orange,
                      ),
                      onPressed: () => _debugCourseData(data['courseId']),
                      tooltip: 'Debug cours',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 22,
                        color: Color(0xFF6B46C1),
                      ),
                      onPressed: () => _likeCourse(data['courseId']),
                      tooltip: 'Liker',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.download_outlined,
                        size: 22,
                        color: Color(0xFF6B46C1),
                      ),
                      onPressed: () =>
                          _downloadCourse(data['pdfPath'], data['courseId']),
                      tooltip: 'Télécharger',
                    ),
                    ElevatedButton(
                      onPressed: () => _openEnrolledCourse(data['courseId']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                        elevation: 2,
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
          Icon(Icons.book_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Inter',
            ),
          ),
          if (message == 'Aucun cours inscrit')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Découvrir des cours'),
              ),
            ),
        ],
      ),
    );
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
        'pdfPath': courseData['pdfPath'],
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          backgroundColor: isError
              ? const Color(0xFFE53E3E)
              : const Color(0xFF38A169),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: Duration(seconds: isError ? 4 : 2),
          elevation: 4,
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
      'likeCount': 0,
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
      appBar: AppBar(
        title: const Text(
          'Lecture du PDF',
          style: TextStyle(fontFamily: 'Inter', fontSize: 18),
        ),
        backgroundColor: const Color(0xFF6B46C1),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Téléchargement en cours...',
                    style: TextStyle(fontFamily: 'Inter'),
                  ),
                  backgroundColor: Color(0xFF38A169),
                ),
              );
            },
            tooltip: 'Télécharger le PDF',
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
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
                        query.docs.first.reference.update({
                          'progress': progress,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Progression : $progress%'),
                            backgroundColor: const Color(0xFF38A169),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    });
              }
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Page ${currentPage ?? 0} sur ${pages ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

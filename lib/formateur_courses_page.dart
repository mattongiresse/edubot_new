import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import 'supabase_config.dart';
import 'supabase_storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

class FormateurCoursesPage extends StatefulWidget {
  final String userName;
  const FormateurCoursesPage({super.key, required this.userName});

  @override
  State<FormateurCoursesPage> createState() => _FormateurCoursesPageState();
}

class _FormateurCoursesPageState extends State<FormateurCoursesPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Informatique';
  PlatformFile? _selectedPdfFile;
  bool _isUploading = false;
  String? _uploadedPdfUrl;
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initializeComponents();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() {});
    });
    _animationController.forward();
  }

  Future<void> _initializeComponents() async {
    try {
      await SupabaseConfig.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Erreur initialisation Supabase: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Gestion des Cours',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF673AB7), // DeepPurple
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Cours - ${widget.userName}',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF673AB7),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: _showStatistics,
            tooltip: 'Statistiques',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            children: [
              _buildAddCourseSection(),
              const SizedBox(height: 16),
              _buildCoursesListSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCourseSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBadge(),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _titleController,
                labelText: 'Titre du cours *',
                icon: Icons.title,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Le titre est requis'
                    : null,
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Description du cours *',
                icon: Icons.description,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'La description est requise'
                    : null,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _buildPdfSelector(),
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add_circle, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Créer un nouveau cours',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF673AB7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black,
      ), // Texte en noir pour contraste
      decoration: InputDecoration(
        labelText: 'Catégorie *',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: const Icon(
          Icons.category,
          color: Color(0xFF673AB7),
        ), // Icône violette
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF673AB7), // Bordure violette
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF9575CD), // Bordure violette plus claire
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2),
        ),
        filled: true,
        fillColor: Colors.white, // Fond blanc
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: GoogleFonts.poppins(color: Colors.black),
              ), // Texte des options en noir
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategory = val);
      },
      validator: (val) =>
          val == null ? 'Veuillez sélectionner une catégorie' : null,
    );
  }

  Widget _buildPdfSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPdfFile != null
              ? const Color(0xFF4CAF50)
              : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedPdfFile != null
            ? const Color(0xFFE8F5E9)
            : Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedPdfFile != null
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                      _selectedPdfFile != null
                          ? const Color(0xFF81C784)
                          : Colors.grey[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPdfFile != null
                                ? 'Fichier sélectionné'
                                : 'Aucun fichier sélectionné',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _selectedPdfFile != null
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4CAF50),
                                const Color(0xFF81C784),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPdfFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedPdfFile!.name,
                        style: GoogleFonts.poppins(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(_selectedPdfFile!.size),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickPdfFile,
                icon: Icon(
                  _selectedPdfFile != null
                      ? Icons.change_circle
                      : Icons.upload_file,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  _selectedPdfFile != null ? 'Changer' : 'Choisir PDF',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
          if (_selectedPdfFile == null) ...[
            const SizedBox(height: 8),
            Text(
              'Upload vers Supabase Storage\nFormats acceptés: PDF uniquement\nTaille maximale: 50 MB',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _isUploading ? null : _addCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF673AB7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload vers Supabase...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Créer le cours',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildCoursesListSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoursesHeader(),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _buildCoursesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.library_books, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          'Mes cours créés',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Veuillez vous connecter pour voir vos cours',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('formateurId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Erreur Firestore: ${snapshot.error}');
          print('Stack trace: ${snapshot.stackTrace}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Réessayer',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun cours créé',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier cours avec Supabase !',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final courses = snapshot.data!.docs;
        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final data = course.data() as Map<String, dynamic>? ?? {};
            return _buildCourseCard(course.id, data);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> courseData) {
    final enrollmentCount = courseData['enrollmentCount'] ?? 0;
    final downloadCount = courseData['downloadCount'] ?? 0;
    final likes = courseData['likes'] ?? 0;
    final isSupabaseFile = courseData['storageProvider'] == 'supabase';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseHeader(courseId, courseData, isSupabaseFile),
              const SizedBox(height: 12),
              _buildCourseDescription(courseData),
              const SizedBox(height: 12),
              _buildCourseFileRow(courseData),
              const SizedBox(height: 12),
              _buildCourseStatsRow(
                enrollmentCount,
                downloadCount,
                likes,
                courseData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(
    String courseId,
    Map<String, dynamic> courseData,
    bool isSupabaseFile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      courseData['title'] ?? 'Sans titre',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (isSupabaseFile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50),
                            const Color(0xFF81C784),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  courseData['category'] ?? 'Sans catégorie',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2196F3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Modifier', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  const Icon(Icons.copy, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Dupliquer', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem(
              value: courseData['isActive'] == true ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    courseData['isActive'] == true
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    courseData['isActive'] == true ? 'Désactiver' : 'Activer',
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Supprimer',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) =>
              _handleCourseAction(value, courseId, courseData),
        ),
      ],
    );
  }

  Widget _buildCourseDescription(Map<String, dynamic> courseData) {
    return Text(
      courseData['description'] ?? 'Aucune description',
      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCourseFileRow(Map<String, dynamic> courseData) {
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            courseData['fileName'] ?? 'Document.pdf',
            style: GoogleFonts.poppins(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _formatFileSize(courseData['fileSize'] ?? 0),
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCourseStatsRow(
    int enrollmentCount,
    int downloadCount,
    int likes,
    Map<String, dynamic> courseData,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          Icons.people,
          '$enrollmentCount',
          'Inscrits',
          const Color(0xFF2196F3),
        ),
        _buildStatItem(
          Icons.download,
          '$downloadCount',
          'Téléchargements',
          const Color(0xFF4CAF50),
        ),
        _buildStatItem(
          Icons.thumb_up,
          '$likes',
          'Likes',
          const Color(0xFFFF9800),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: courseData['isActive'] == true
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            courseData['isActive'] == true ? 'Actif' : 'Inactif',
            style: GoogleFonts.poppins(
              color: courseData['isActive'] == true
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 50 * 1024 * 1024) {
          _showSnackBar(
            'Le fichier est trop volumineux (max 50MB)',
            isError: true,
          );
          return;
        }
        setState(() {
          _selectedPdfFile = file;
        });
        _showSnackBar('PDF sélectionné: ${file.name}');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection: $e', isError: true);
    }
  }

  Future<String?> _uploadPdfToSupabaseWithPath(String fileName) async {
    if (_selectedPdfFile == null) return null;

    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      String? downloadUrl;

      if (kIsWeb) {
        if (_selectedPdfFile!.bytes == null ||
            _selectedPdfFile!.bytes!.isEmpty) {
          throw Exception('Fichier non chargé correctement sur le web');
        }
        downloadUrl = await SupabaseStorageService.uploadPdf(
          fileName: fileName,
          fileData: _selectedPdfFile!.bytes!,
          userId: user.uid,
          isWeb: true,
        );
      } else {
        if (_selectedPdfFile!.path == null || _selectedPdfFile!.path!.isEmpty) {
          throw Exception('Chemin de fichier non disponible');
        }
        downloadUrl = await SupabaseStorageService.uploadPdf(
          fileName: fileName,
          fileData: File(_selectedPdfFile!.path!),
          userId: user.uid,
          isWeb: false,
        );
      }

      setState(() {
        _isUploading = false;
        _uploadedPdfUrl = downloadUrl;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar(
        'Erreur lors de l\'upload du fichier vers Supabase: $e',
        isError: true,
      );
      return null;
    }
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPdfFile == null) {
      _showSnackBar('Veuillez sélectionner un fichier PDF', isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', isError: true);
        return;
      }

      final title = _titleController.text.trim().isEmpty
          ? 'untitled_course'
          : _titleController.text
                .trim()
                .replaceAll(' ', '_')
                .replaceAll(RegExp(r'[^\w\-_.]'), '');

      final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Upload vers Supabase et récupérer l'URL
      final pdfUrl = await _uploadPdfToSupabaseWithPath(fileName);
      if (pdfUrl == null) return;

      // Extraire le vrai chemin du fichier depuis l'URL retournée
      final realPath = _extractPathFromUrl(pdfUrl);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Profil formateur introuvable');
      }

      final userData = userDoc.data()!;
      final formateurNom =
          '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim();

      await FirebaseFirestore.instance.collection('courses').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'pdfPath': realPath, // Utiliser le vrai chemin
        'fileName': _selectedPdfFile!.name,
        'storageProvider': 'supabase',
        'formateurId': user.uid,
        'formateurNom': formateurNom,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'fileSize': _selectedPdfFile!.size,
        'likes': 0,
        'enrollmentCount': 0,
        'downloadCount': 0,
      });

      _resetForm();
      _showSnackBar('Cours créé avec succès !');
    } catch (e) {
      _showSnackBar('Erreur lors de la création du cours: $e', isError: true);
    }
  }

  // Nouvelle méthode pour extraire le chemin depuis l'URL
  String _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('course-files');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
      return url;
    } catch (e) {
      print('Erreur extraction chemin URL: $e');
      return url;
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedPdfFile = null;
      _uploadedPdfUrl = null;
      _selectedCategory = 'Informatique';
    });
  }

  void _handleCourseAction(
    String action,
    String courseId,
    Map<String, dynamic> courseData,
  ) {
    switch (action) {
      case 'edit':
        _showEditDialog(courseId, courseData);
        break;
      case 'duplicate':
        _duplicateCourse(courseData);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCourseStatus(courseId, action == 'activate');
        break;
      case 'delete':
        _showDeleteConfirmation(courseId, courseData);
        break;
    }
  }

  void _showEditDialog(String courseId, Map<String, dynamic> courseData) {
    final titleController = TextEditingController(text: courseData['title']);
    final descController = TextEditingController(
      text: courseData['description'],
    );
    String selectedCategory = courseData['category'] ?? _categories.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Modifier le cours',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF673AB7),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF673AB7),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) =>
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF673AB7),
                            width: 2,
                          ),
                        ),
                      ),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: GoogleFonts.poppins()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedCategory = val!),
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCourse(
                courseId,
                titleController.text,
                descController.text,
                selectedCategory,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Modifier',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCourse(
    String courseId,
    String title,
    String description,
    String category,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
            'title': title,
            'description': description,
            'category': category,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _showSnackBar('Cours modifié avec succès');
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la modification du cours: $e',
        isError: true,
      );
    }
  }

  Future<void> _duplicateCourse(Map<String, dynamic> courseData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Utilisateur non connecté', isError: true);
        return;
      }

      // Récupérer les données de l'utilisateur pour formateurNom
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Profil formateur introuvable');
      }

      final userData = userDoc.data()!;
      final formateurNom =
          '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim();

      await FirebaseFirestore.instance.collection('courses').add({
        'title':
            courseData['title'] ??
            'Cours dupliqué', // Utiliser le titre du cours existant
        'description':
            courseData['description'] ??
            '', // Utiliser la description existante
        'category': courseData['category'] ?? _selectedCategory,
        'pdfUrl': courseData['pdfUrl'], // Utiliser l'URL PDF existante
        'pdfPath': courseData['pdfPath'] ?? 'Document.pdf', // Nom du fichier
        'storageProvider': courseData['storageProvider'] ?? 'supabase',
        'formateurId': user.uid,
        'formateurNom': formateurNom, // Nom du formateur récupéré
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'fileSize': courseData['fileSize'] ?? 0, // Taille du fichier
        'fileName': courseData['fileName'] ?? 'Document.pdf', // Nom du fichier
        'likes': 0,
        'enrollmentCount': 0,
        'downloadCount': 0,
      });

      _showSnackBar('Cours dupliqué avec succès');
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la duplication du cours: $e',
        isError: true,
      );
    }
  }

  Future<void> _toggleCourseStatus(String courseId, bool activate) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
            'isActive': activate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      _showSnackBar(activate ? 'Cours activé' : 'Cours désactivé');
    } catch (e) {
      _showSnackBar(
        'Erreur lors du changement de statut du cours: $e',
        isError: true,
      );
    }
  }

  Future<void> _deleteCourse(
    String courseId,
    Map<String, dynamic> courseData,
  ) async {
    try {
      final pdfUrl = courseData['pdfUrl'] as String?;
      final isSupabaseFile = courseData['storageProvider'] == 'supabase';

      if (pdfUrl != null && pdfUrl.isNotEmpty && isSupabaseFile) {
        final filePath = SupabaseStorageService.extractFilePathFromUrl(pdfUrl);
        if (filePath != null) {
          await SupabaseStorageService.deleteFile(filePath);
        }
      }

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();

      final enrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      for (var doc in enrollments.docs) {
        await doc.reference.delete();
      }

      _showSnackBar('Cours supprimé avec succès');
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la suppression du cours: $e',
        isError: true,
      );
    }
  }

  void _showDeleteConfirmation(
    String courseId,
    Map<String, dynamic> courseData,
  ) {
    final isSupabaseFile = courseData['storageProvider'] == 'supabase';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirmer la suppression',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer ce cours ?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Cette action est irréversible et supprimera :',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Text(
              '• Le fichier PDF ${isSupabaseFile ? "(Supabase)" : "(Firebase)"}',
              style: GoogleFonts.poppins(),
            ),
            Text('• Toutes les inscriptions', style: GoogleFonts.poppins()),
            Text('• Les données du cours', style: GoogleFonts.poppins()),
            if (isSupabaseFile) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Fichier stocké sur Supabase Storage',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(courseId, courseData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(
              'Statistiques',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Supabase',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                    .collection('courses')
                    .where(
                      'formateurId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                    )
                    .snapshots(),
          builder: (context, snapshot) {
            if (FirebaseAuth.instance.currentUser == null) {
              return Center(
                child: Text(
                  'Veuillez vous connecter pour voir les statistiques',
                  style: GoogleFonts.poppins(),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Erreur Firestore (statistiques): ${snapshot.error}');
              print('Stack trace: ${snapshot.stackTrace}');
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red[600]),
                ),
              );
            }

            final courses = snapshot.data!.docs;
            int totalCourses = courses.length;
            int activeCourses = courses
                .where((c) => (c.data() as Map)['isActive'] == true)
                .length;
            int supabaseCourses = courses
                .where(
                  (c) => (c.data() as Map)['storageProvider'] == 'supabase',
                )
                .length;
            int totalEnrollments = courses.fold(
              0,
              (sum, c) =>
                  sum + ((c.data() as Map)['enrollmentCount'] ?? 0) as int,
            );
            int totalDownloads = courses.fold(
              0,
              (sum, c) =>
                  sum + ((c.data() as Map)['downloadCount'] ?? 0) as int,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('Cours total', totalCourses.toString()),
                _buildStatRow('Cours actifs', activeCourses.toString()),
                _buildStatRow('Fichiers Supabase', supabaseCourses.toString()),
                _buildStatRow(
                  'Inscriptions totales',
                  totalEnrollments.toString(),
                ),
                _buildStatRow('Téléchargements', totalDownloads.toString()),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins()),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF673AB7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: isError
              ? const Color(0xFFE53935)
              : const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: isError
              ? SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                )
              : null,
        ),
      );
    }
  }
}

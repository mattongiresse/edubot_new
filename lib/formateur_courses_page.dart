// formateur_courses_improved.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class FormateurCoursesImproved extends StatefulWidget {
  const FormateurCoursesImproved({super.key});

  @override
  State<FormateurCoursesImproved> createState() =>
      _FormateurCoursesImprovedState();
}

class _FormateurCoursesImprovedState extends State<FormateurCoursesImproved> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Informatique';
  PlatformFile? _selectedPdfFile;
  bool _isUploading = false;
  String? _uploadedPdfUrl;

  final List<String> _categories = [
    'Informatique',
    'Mathématiques',
    'Sciences',
    'Langues',
    'Histoire',
    'Économie',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatistics,
            tooltip: 'Statistiques',
          ),
        ],
      ),
      body: Column(
        children: [
          // SECTION AJOUT DE COURS - Réduite
          _buildAddCourseSection(),

          const Divider(height: 1),

          // SECTION LISTE DES COURS
          Expanded(child: _buildCoursesListSection()),
        ],
      ),
    );
  }

  Widget _buildAddCourseSection() {
    return Container(
      margin: const EdgeInsets.all(12), // Réduit de 16 à 12
      padding: const EdgeInsets.all(16), // Réduit de 20 à 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Réduit de 15 à 12
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8, // Réduit de 10 à 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête - Compact
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Réduit de 8 à 6
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6), // Réduit de 8 à 6
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: Colors.deepPurple,
                    size: 20, // Réduit de 24 à 20
                  ),
                ),
                const SizedBox(width: 10), // Réduit de 12 à 10
                const Expanded(
                  child: Text(
                    'Créer un nouveau cours',
                    style: TextStyle(
                      fontSize: 18, // Réduit de 20 à 18
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                if (kIsWeb)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Réduit de 8 à 6
                      vertical: 3, // Réduit de 4 à 3
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'WEB',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 9, // Réduit de 10 à 9
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14), // Réduit de 20 à 14
            // Champ titre
            _buildTextFormField(
              controller: _titleController,
              labelText: 'Titre du cours *',
              icon: Icons.title,
              validator: (val) =>
                  val!.trim().isEmpty ? 'Le titre est requis' : null,
              maxLines: 1,
            ),

            const SizedBox(height: 12), // Réduit de 16 à 12
            // Champ description
            _buildTextFormField(
              controller: _descriptionController,
              labelText: 'Description du cours *',
              icon: Icons.description,
              validator: (val) =>
                  val!.trim().isEmpty ? 'La description est requise' : null,
              maxLines: 2, // Réduit de 3 à 2
            ),

            const SizedBox(height: 12), // Réduit de 16 à 12
            // Sélecteur de catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Catégorie *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Réduit de 10 à 8
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12, // Réduit le padding vertical
                ),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              validator: (val) =>
                  val == null ? 'Veuillez sélectionner une catégorie' : null,
            ),

            const SizedBox(height: 12), // Réduit de 16 à 12
            // Sélection de fichier PDF - Compact
            _buildPdfSelector(),

            const SizedBox(height: 16), // Réduit de 24 à 16
            // Bouton d'ajout
            _buildSubmitButton(),
          ],
        ),
      ),
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
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ), // Réduit de 10 à 8
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12, // Padding vertical réduit
        ),
        counterText: maxLines > 1 ? null : '',
      ),
      validator: validator,
    );
  }

  Widget _buildPdfSelector() {
    return Container(
      padding: const EdgeInsets.all(12), // Réduit de 16 à 12
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPdfFile != null ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8), // Réduit de 10 à 8
        color: _selectedPdfFile != null
            ? Colors.green.shade50
            : Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Réduit de 8 à 6
                decoration: BoxDecoration(
                  color: _selectedPdfFile != null ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(6), // Réduit de 8 à 6
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 20, // Réduit de 24 à 20
                ),
              ),
              const SizedBox(width: 10), // Réduit de 12 à 10
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPdfFile != null
                          ? 'Fichier sélectionné'
                          : 'Aucun fichier sélectionné',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Réduit la taille de police
                        color: _selectedPdfFile != null
                            ? Colors.green
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (_selectedPdfFile != null) ...[
                      const SizedBox(height: 2), // Réduit de 4 à 2
                      Text(
                        _selectedPdfFile!.name,
                        style: const TextStyle(
                          fontSize: 12,
                        ), // Réduit de 14 à 12
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(_selectedPdfFile!.size),
                        style: TextStyle(
                          fontSize: 11, // Réduit de 12 à 11
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickPdfFile,
                icon: Icon(
                  _selectedPdfFile != null
                      ? Icons.change_circle
                      : Icons.upload_file,
                  size: 18, // Réduit la taille de l'icône
                ),
                label: Text(
                  _selectedPdfFile != null ? 'Changer' : 'Choisir PDF',
                  style: const TextStyle(
                    fontSize: 12,
                  ), // Réduit la taille du texte
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // Réduit le padding
                    vertical: 8, // Réduit le padding vertical
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6), // Réduit de 8 à 6
                  ),
                ),
              ),
            ],
          ),
          if (_selectedPdfFile == null) ...[
            const SizedBox(height: 6), // Réduit de 8 à 6
            Text(
              'Formats acceptés: PDF uniquement\nTaille maximale recommandée: 50 MB',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ), // Réduit de 12 à 11
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _addCourse,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14), // Réduit de 16 à 14
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ), // Réduit de 10 à 8
        elevation: 2,
      ),
      child: _isUploading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18, // Réduit de 20 à 18
                  height: 18, // Réduit de 20 à 18
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 10), // Réduit de 12 à 10
                const Text(
                  'Upload en cours...',
                  style: TextStyle(fontSize: 15), // Réduit de 16 à 15
                ),
              ],
            )
          : const Text(
              'Créer le cours',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ), // Réduit de 16 à 15
            ),
    );
  }

  Widget _buildCoursesListSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12), // Réduit de 16 à 12
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12), // Réduit de 16 à 12
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Réduit de 8 à 6
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Réduit de 8 à 6
                ),
                child: const Icon(
                  Icons.library_books,
                  color: Colors.deepPurple,
                  size: 18, // Réduit de 20 à 18
                ),
              ),
              const SizedBox(width: 6), // Réduit de 8 à 6
              const Text(
                'Mes cours créés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ), // Réduit de 18 à 16
              ),
            ],
          ),
          const SizedBox(height: 10), // Réduit de 12 à 10
          Expanded(child: _buildCoursesList()),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des cours',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
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
                Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun cours créé',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier cours ci-dessus !',
                  style: TextStyle(color: Colors.grey.shade500),
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
            final data = course.data() as Map<String, dynamic>;
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          courseData['category'] ?? '',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
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
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Dupliquer'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: courseData['isActive'] == true
                          ? 'deactivate'
                          : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            courseData['isActive'] == true
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            courseData['isActive'] == true
                                ? 'Désactiver'
                                : 'Activer',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
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
                      _handleCourseAction(value, courseId, courseData),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              courseData['description'] ?? 'Aucune description',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  courseData['fileName'] ?? 'Document.pdf',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  _formatFileSize(courseData['fileSize'] ?? 0),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  '$enrollmentCount',
                  'Inscrits',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.download,
                  '$downloadCount',
                  'Téléchargements',
                  Colors.green,
                ),
                _buildStatItem(
                  Icons.thumb_up,
                  '$likes',
                  'Likes',
                  Colors.orange,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: courseData['isActive'] == true
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    courseData['isActive'] == true ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      color: courseData['isActive'] == true
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // MÉTHODES FONCTIONNELLES

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

        // Vérifier la taille (max 50MB)
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

  Future<String?> _uploadPdfToStorage() async {
    if (_selectedPdfFile == null) return null;

    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final title = _titleController.text.trim().isEmpty
          ? 'untitled_course'
          : _titleController.text
                .trim()
                .replaceAll(' ', '_')
                .replaceAll(RegExp(r'[^\w\-_.]'), '');

      final fileName =
          'courses/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$title.pdf';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        if (_selectedPdfFile!.bytes == null ||
            _selectedPdfFile!.bytes!.isEmpty) {
          throw Exception('Fichier non chargé correctement sur le web');
        }
        uploadTask = ref.putData(
          _selectedPdfFile!.bytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else {
        if (_selectedPdfFile!.path == null || _selectedPdfFile!.path!.isEmpty) {
          throw Exception('Chemin de fichier non disponible');
        }
        uploadTask = ref.putFile(File(_selectedPdfFile!.path!));
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _uploadedPdfUrl = downloadUrl;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar('Erreur d\'upload: $e', isError: true);
      return null;
    }
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPdfFile == null) {
      _showSnackBar('Veuillez sélectionner un fichier PDF', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Utilisateur non connecté', isError: true);
      return;
    }

    try {
      // Upload du PDF
      final pdfUrl = await _uploadPdfToStorage();
      if (pdfUrl == null) return;

      // Récupérer les infos du formateur
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

      // Créer le cours dans Firestore
      await FirebaseFirestore.instance.collection('courses').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'pdfUrl': pdfUrl,
        'formateurId': user.uid,
        'formateurNom': formateurNom,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'fileSize': _selectedPdfFile!.size,
        'fileName': _selectedPdfFile!.name,
        'likes': 0,
        'enrollmentCount': 0,
        'downloadCount': 0,
      });

      // Réinitialiser le formulaire
      _resetForm();

      _showSnackBar('Cours créé avec succès ! 🎉');
    } catch (e) {
      _showSnackBar('Erreur lors de la création: $e', isError: true);
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
        _showDeleteConfirmation(courseId, courseData['pdfUrl']);
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
        title: const Text('Modifier le cours'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) =>
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
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
            child: const Text('Annuler'),
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
            child: const Text('Modifier'),
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
      _showSnackBar('Erreur lors de la modification', isError: true);
    }
  }

  Future<void> _duplicateCourse(Map<String, dynamic> courseData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('courses').add({
        'title': '${courseData['title']} (Copie)',
        'description': courseData['description'],
        'category': courseData['category'],
        'pdfUrl': courseData['pdfUrl'],
        'formateurId': user.uid,
        'formateurNom': courseData['formateurNom'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': false, // Inactif par défaut
        'fileSize': courseData['fileSize'],
        'fileName': courseData['fileName'],
        'likes': 0,
        'enrollmentCount': 0,
        'downloadCount': 0,
      });

      _showSnackBar('Cours dupliqué avec succès');
    } catch (e) {
      _showSnackBar('Erreur lors de la duplication', isError: true);
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
      _showSnackBar('Erreur lors du changement de statut', isError: true);
    }
  }

  Future<void> _deleteCourse(String courseId, String? pdfUrl) async {
    try {
      // Supprimer le fichier PDF du Storage
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(pdfUrl).delete();
      }

      // Supprimer le document Firestore
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();

      // Supprimer les inscriptions liées
      final enrollments = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      for (var doc in enrollments.docs) {
        await doc.reference.delete();
      }

      _showSnackBar('Cours supprimé avec succès');
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(String courseId, String? pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer ce cours ?'),
            SizedBox(height: 8),
            Text(
              '⚠️ Cette action est irréversible et supprimera :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Le fichier PDF'),
            Text('• Toutes les inscriptions'),
            Text('• Les données du cours'),
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
              _deleteCourse(courseId, pdfUrl);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
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
        title: const Text('Statistiques'),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where(
                'formateurId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final courses = snapshot.data!.docs;
            int totalCourses = courses.length;
            int activeCourses = courses
                .where((c) => (c.data() as Map)['isActive'] == true)
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
            child: const Text('Fermer'),
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
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
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

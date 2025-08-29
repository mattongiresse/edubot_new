import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCoursesManagementPage extends StatefulWidget {
  const AdminCoursesManagementPage({super.key});

  @override
  State<AdminCoursesManagementPage> createState() =>
      _AdminCoursesManagementPageState();
}

class _AdminCoursesManagementPageState extends State<AdminCoursesManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  final String _selectedStatus = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('📚 Gestion des Cours'),
        backgroundColor: const Color(0xFF1B1E23),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tous les Cours', icon: Icon(Icons.library_books)),
            Tab(text: 'En Attente', icon: Icon(Icons.pending)),
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher par titre, formateur...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          items:
                              [
                                    'Tous',
                                    'Informatique',
                                    'Mathématiques',
                                    'Sciences',
                                    'Langues',
                                    'Histoire',
                                    'Économie',
                                  ]
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatsRow(),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoursesTab('Tous'),
                _buildCoursesTab('En Attente'),
                _buildCoursesTab('Approuvé'),
                _buildCoursesTab('Rejeté'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final courses = snapshot.data!.docs;
        final totalCourses = courses.length;
        final pending = courses
            .where(
              (c) =>
                  (c.data() as Map)['approvalStatus'] == 'En Attente' ||
                  (c.data() as Map)['approvalStatus'] == null,
            )
            .length;
        final approved = courses
            .where((c) => (c.data() as Map)['approvalStatus'] == 'Approuvé')
            .length;
        final rejected = courses
            .where((c) => (c.data() as Map)['approvalStatus'] == 'Rejeté')
            .length;

        return Row(
          children: [
            _buildStatChip('Total', totalCourses, Colors.blue),
            const SizedBox(width: 8),
            _buildStatChip('En Attente', pending, Colors.orange),
            const SizedBox(width: 8),
            _buildStatChip('Approuvés', approved, Colors.green),
            const SizedBox(width: 8),
            _buildStatChip('Rejetés', rejected, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCoursesTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getCoursesStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun cours trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final courses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final searchMatch =
              _searchQuery.isEmpty ||
              data['title']?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              data['formateurNom']?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          final categoryMatch =
              _selectedCategory == 'Tous' ||
              data['category'] == _selectedCategory;

          return searchMatch && categoryMatch;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final courseData = course.data() as Map<String, dynamic>;
            return _buildCourseCard(course.id, courseData);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getCoursesStream(String status) {
    if (status == 'Tous') {
      return FirebaseFirestore.instance
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('courses')
          .where('approvalStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Widget _buildCourseCard(String courseId, Map<String, dynamic> courseData) {
    final String approvalStatus = courseData['approvalStatus'] ?? 'En Attente';
    final bool isActive = courseData['isActive'] ?? true;
    final DateTime? createdAt = courseData['createdAt']?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du cours
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(approvalStatus).withOpacity(0.8),
                  _getStatusColor(approvalStatus),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.book, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? 'Sans titre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Par ${courseData['formateurNom'] ?? 'Formateur inconnu'}',
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
                    approvalStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                // Description
                Text(
                  courseData['description'] ?? 'Pas de description',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Informations détaillées
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.category,
                      courseData['category'] ?? 'Non catégorisé',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    if (courseData['fileName'] != null)
                      _buildInfoChip(Icons.picture_as_pdf, 'PDF', Colors.red),
                    const Spacer(),
                    Icon(
                      isActive ? Icons.visibility : Icons.visibility_off,
                      color: isActive ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ],
                ),

                if (createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Créé le ${_formatDate(createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _viewCourseDetails(courseId, courseData),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5), // Réduit de 8 à 5 pixels
                    if (courseData['pdfUrl'] != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdf(courseData['pdfUrl']),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (courseData['pdfUrl'] != null)
                      const SizedBox(width: 5), // Réduit de 8 à 5 pixels
                    Expanded(
                      child: PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          if (approvalStatus == 'En Attente') ...[
                            const PopupMenuItem(
                              value: 'approve',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Approuver'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reject',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Rejeter'),
                                ],
                              ),
                            ),
                          ],
                          PopupMenuItem(
                            value: 'toggle_visibility',
                            child: Row(
                              children: [
                                Icon(
                                  isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(isActive ? 'Masquer' : 'Afficher'),
                              ],
                            ),
                          ),
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
                            value: 'stats',
                            child: Row(
                              children: [
                                Icon(Icons.analytics, size: 18),
                                SizedBox(width: 8),
                                Text('Statistiques'),
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
                    ),
                  ],
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
          Icon(icon, size: 14, color: color),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approuvé':
        return Colors.green;
      case 'Rejeté':
        return Colors.red;
      case 'En Attente':
      default:
        return Colors.orange;
    }
  }

  void _handleCourseAction(
    String action,
    String courseId,
    Map<String, dynamic> courseData,
  ) {
    switch (action) {
      case 'approve':
        _approveCourse(courseId);
        break;
      case 'reject':
        _showRejectDialog(courseId);
        break;
      case 'toggle_visibility':
        _toggleCourseVisibility(courseId, courseData['isActive'] ?? true);
        break;
      case 'edit':
        _showEditCourseDialog(courseId, courseData);
        break;
      case 'stats':
        _showCourseStats(courseId, courseData);
        break;
      case 'delete':
        _showDeleteConfirmation(courseId, courseData);
        break;
    }
  }

  void _viewCourseDetails(String courseId, Map<String, dynamic> courseData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      courseData['title'] ?? 'Sans titre',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('ID du cours', courseId),
                      _buildDetailRow('Titre', courseData['title'] ?? 'N/A'),
                      _buildDetailRow(
                        'Description',
                        courseData['description'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Catégorie',
                        courseData['category'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Formateur',
                        courseData['formateurNom'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Statut d\'approbation',
                        courseData['approvalStatus'] ?? 'En Attente',
                      ),
                      _buildDetailRow(
                        'Visibilité',
                        courseData['isActive'] == true ? 'Visible' : 'Masqué',
                      ),
                      _buildDetailRow(
                        'Nom du fichier',
                        courseData['fileName'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Date de création',
                        courseData['createdAt'] != null
                            ? _formatDate(courseData['createdAt'].toDate())
                            : 'N/A',
                      ),

                      const Divider(height: 32),
                      const Text(
                        '📊 Statistiques du cours:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildCourseStatsWidget(courseId),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  if (courseData['approvalStatus'] == 'En Attente') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveCourse(courseId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectDialog(courseId);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCourseStatsWidget(String courseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('Chargement...');

        final enrollments = snapshot.data!.docs;
        final completedEnrollments = enrollments
            .where((e) => (e.data() as Map)['isCompleted'] == true)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Inscriptions: ${enrollments.length}'),
            Text('• Complétions: $completedEnrollments'),
            Text(
              '• Taux de completion: ${enrollments.isNotEmpty ? ((completedEnrollments / enrollments.length) * 100).toStringAsFixed(1) : 0}%',
            ),
          ],
        );
      },
    );
  }

  void _approveCourse(String courseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
            'approvalStatus': 'Approuvé',
            'approvedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cours approuvé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(String courseId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le cours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Raison du rejet...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .update({
                      'approvalStatus': 'Rejeté',
                      'rejectionReason': reasonController.text.trim(),
                      'rejectedAt': FieldValue.serverTimestamp(),
                      'isActive': false,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cours rejeté'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _toggleCourseVisibility(String courseId, bool currentVisibility) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({
            'isActive': !currentVisibility,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentVisibility ? 'Cours masqué' : 'Cours rendu visible',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditCourseDialog(String courseId, Map<String, dynamic> courseData) {
    final TextEditingController titleController = TextEditingController(
      text: courseData['title'],
    );
    final TextEditingController descriptionController = TextEditingController(
      text: courseData['description'],
    );
    String selectedCategory = courseData['category'] ?? 'Informatique';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le cours'),
        content: SingleChildScrollView(
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
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items:
                    [
                          'Informatique',
                          'Mathématiques',
                          'Sciences',
                          'Langues',
                          'Histoire',
                          'Économie',
                        ]
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) => selectedCategory = value!,
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
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .update({
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cours modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showCourseStats(String courseId, Map<String, dynamic> courseData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '📊 Statistiques du cours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                courseData['title'] ?? 'Sans titre',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('enrollments')
                      .where('courseId', isEqualTo: courseId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final enrollments = snapshot.data!.docs;
                    final totalEnrollments = enrollments.length;
                    final completedEnrollments = enrollments
                        .where((e) => (e.data() as Map)['isCompleted'] == true)
                        .length;
                    final averageProgress = enrollments.isNotEmpty
                        ? enrollments.fold<double>(
                                0,
                                (sum, e) =>
                                    sum + ((e.data() as Map)['progress'] ?? 0),
                              ) /
                              enrollments.length
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          'Total des inscriptions',
                          totalEnrollments.toString(),
                        ),
                        _buildStatRow(
                          'Cours complétés',
                          completedEnrollments.toString(),
                        ),
                        _buildStatRow(
                          'Taux de complétion',
                          '${totalEnrollments > 0 ? ((completedEnrollments / totalEnrollments) * 100).toStringAsFixed(1) : 0}%',
                        ),
                        _buildStatRow(
                          'Progression moyenne',
                          '${averageProgress.toStringAsFixed(1)}%',
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          '📋 Étudiants inscrits:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: ListView.builder(
                            itemCount: enrollments.length,
                            itemBuilder: (context, index) {
                              final enrollment = enrollments[index];
                              final data =
                                  enrollment.data() as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: data['isCompleted'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Text(
                                    '${data['progress'] ?? 0}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                title: Text(data['studentName'] ?? 'Étudiant'),
                                subtitle: Text(
                                  'Progression: ${data['progress'] ?? 0}%',
                                ),
                                trailing: Icon(
                                  data['isCompleted'] == true
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: data['isCompleted'] == true
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    String courseId,
    Map<String, dynamic> courseData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le cours '
          '"${courseData['title']}" ? '
          'Cette action supprimera également toutes les inscriptions associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Supprimer les inscriptions associées
                final enrollments = await FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('courseId', isEqualTo: courseId)
                    .get();

                for (var enrollment in enrollments.docs) {
                  await enrollment.reference.delete();
                }

                // Supprimer le cours
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cours supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openPdf(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

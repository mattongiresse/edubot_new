import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersManagementPage extends StatefulWidget {
  const AdminUsersManagementPage({super.key});

  @override
  State<AdminUsersManagementPage> createState() =>
      _AdminUsersManagementPageState();
}

class _AdminUsersManagementPageState extends State<AdminUsersManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedUserType = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('👥 Gestion des Utilisateurs'),
        backgroundColor: const Color(0xFF1B1E23),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous les Utilisateurs', icon: Icon(Icons.people)),
            Tab(text: 'Étudiants', icon: Icon(Icons.school)),
            Tab(text: 'Formateurs', icon: Icon(Icons.person_outline)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'Ajouter un utilisateur',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher par nom, email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUserType,
                          items: ['Tous', 'Étudiant', 'Formateur', 'Admin']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedUserType = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatsRow(),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab('Tous'),
                _buildUsersTab('Étudiant'),
                _buildUsersTab('Formateur'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final users = snapshot.data!.docs;
        final totalUsers = users.length;
        final students = users
            .where((u) => (u.data() as Map)['statut'] == 'Étudiant')
            .length;
        final instructors = users
            .where((u) => (u.data() as Map)['statut'] == 'Formateur')
            .length;
        final admins = users
            .where((u) => (u.data() as Map)['statut'] == 'Admin')
            .length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatChip('Total', totalUsers, Colors.blue),
              const SizedBox(width: 6),
              _buildStatChip('Étudiants', students, Colors.green),
              const SizedBox(width: 6),
              _buildStatChip('Formateurs', instructors, Colors.orange),
              const SizedBox(width: 6),
              _buildStatChip('Admins', admins, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildUsersTab(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Aucun utilisateur trouvé',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Filtre de recherche par nom, prénom ou email
          final searchMatch =
              _searchQuery.isEmpty ||
              data['nom']?.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              data['prenom']?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              data['email']?.toLowerCase().contains(_searchQuery.toLowerCase());

          // Filtre par type d'utilisateur du dropdown (seulement si ce n'est pas "Tous")
          bool typeMatch = true;
          if (_selectedUserType != 'Tous') {
            typeMatch = data['statut'] == _selectedUserType;
          }

          return searchMatch && typeMatch;
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Aucun résultat pour cette recherche',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            return _buildUserCard(user.id, userData);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getUsersStream(String userType) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'users',
    );

    // Appliquer le filtre par onglet immédiatement
    if (userType != 'Tous') {
      query = query.where('statut', isEqualTo: userType);
    }

    // Ajouter l'ordre par date de création si possible
    try {
      return query.orderBy('createdAt', descending: true).snapshots();
    } catch (e) {
      // Fallback si l'index n'est pas créé
      return query.snapshots();
    }
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final String role = userData['statut'] ?? 'Non défini';
    final bool isActive = userData['isActive'] ?? true;
    final DateTime? createdAt = userData['createdAt']?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(role),
              child: Text(
                '${userData['prenom']?[0] ?? ''}${userData['nom']?[0] ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                          '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userData['email'] ?? 'Email non disponible',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Inscrit le ${_formatDate(createdAt)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'Actif' : 'Inactif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 6),
                          Text('Voir Détails'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 6),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            size: 16,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleUserAction(value, userId, userData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Étudiant':
        return Colors.blue;
      case 'Formateur':
        return Colors.green;
      case 'Admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(
    String action,
    String userId,
    Map<String, dynamic> userData,
  ) {
    switch (action) {
      case 'view':
        _showUserDetails(userId, userData);
        break;
      case 'edit':
        _showEditUserDialog(userId, userData);
        break;
      case 'toggle_status':
        _toggleUserStatus(userId, userData['isActive'] ?? true);
        break;
      case 'delete':
        _showDeleteConfirmation(userId, userData);
        break;
    }
  }

  void _showUserDetails(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails: ${userData['prenom']} ${userData['nom']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', userId),
              _buildDetailRow('Email', userData['email'] ?? 'N/A'),
              _buildDetailRow('Rôle', userData['statut'] ?? 'N/A'),
              _buildDetailRow(
                'Status',
                userData['isActive'] == true ? 'Actif' : 'Inactif',
              ),
              _buildDetailRow('Téléphone', userData['telephone'] ?? 'N/A'),
              _buildDetailRow(
                'Date d\'inscription',
                userData['createdAt'] != null
                    ? _formatDate(userData['createdAt'].toDate())
                    : 'N/A',
              ),
              if (userData['statut'] == 'Étudiant') ...[
                const Divider(),
                const Text(
                  '📊 Statistiques Étudiant:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStudentStats(userId),
              ],
              if (userData['statut'] == 'Formateur') ...[
                const Divider(),
                const Text(
                  '📚 Statistiques Formateur:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildInstructorStats(userId),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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

  Widget _buildStudentStats(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('Chargement...');

        final enrollments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Cours suivis: ${enrollments.length}'),
            Text(
              '• Cours complétés: ${enrollments.where((e) => (e.data() as Map)['isCompleted'] == true).length}',
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructorStats(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('formateurId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('Chargement...');

        final courses = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Cours créés: ${courses.length}'),
            Text(
              '• Cours actifs: ${courses.where((c) => (c.data() as Map)['isActive'] != false).length}',
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    final TextEditingController prenomController = TextEditingController(
      text: userData['prenom'],
    );
    final TextEditingController nomController = TextEditingController(
      text: userData['nom'],
    );
    final TextEditingController emailController = TextEditingController(
      text: userData['email'],
    );
    final TextEditingController telephoneController = TextEditingController(
      text: userData['telephone'],
    );

    String selectedRole = userData['statut'] ?? 'Étudiant';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier Utilisateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: ['Étudiant', 'Formateur', 'Admin']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) => selectedRole = value!,
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
                    .collection('users')
                    .doc(userId)
                    .update({
                      'prenom': prenomController.text.trim(),
                      'nom': nomController.text.trim(),
                      'email': emailController.text.trim(),
                      'telephone': telephoneController.text.trim(),
                      'statut': selectedRole,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utilisateur modifié avec succès'),
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

  void _showAddUserDialog() {
    final TextEditingController prenomController = TextEditingController();
    final TextEditingController nomController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController telephoneController = TextEditingController();

    String selectedRole = 'Étudiant';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un Utilisateur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: ['Étudiant', 'Formateur', 'Admin']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) => selectedRole = value!,
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
                final userCredential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .set({
                      'prenom': prenomController.text.trim(),
                      'nom': nomController.text.trim(),
                      'email': emailController.text.trim(),
                      'telephone': telephoneController.text.trim(),
                      'statut': selectedRole,
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utilisateur créé avec succès'),
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
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus ? 'Utilisateur désactivé' : 'Utilisateur activé',
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

  void _showDeleteConfirmation(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'utilisateur '
          '${userData['prenom']} ${userData['nom']} ? '
          'Cette action est irréversible.',
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
                    .collection('users')
                    .doc(userId)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utilisateur supprimé avec succès'),
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

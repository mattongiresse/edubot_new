import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_users_management_page.dart';
import 'admin_courses_management_page.dart';
import 'admin_system_settings_page.dart';
import 'admin_payments_page.dart';
import 'admin_support_page.dart';
import 'admin_analytics_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String adminName;

  const AdminDashboardPage({super.key, required this.adminName});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _systemStats = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadSystemStatistics();
  }

  Future<void> _loadSystemStatistics() async {
    try {
      // Charger les statistiques système
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .get();

      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .get();

      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .get();

      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .get();

      // Calculer les statistiques
      final totalUsers = usersSnapshot.docs.length;
      final totalStudents = usersSnapshot.docs
          .where((doc) => doc.data()['statut'] == 'Étudiant')
          .length;
      final totalInstructors = usersSnapshot.docs
          .where((doc) => doc.data()['statut'] == 'Formateur')
          .length;

      final totalCourses = coursesSnapshot.docs.length;
      final activeCourses = coursesSnapshot.docs
          .where((doc) => doc.data()['isActive'] ?? true)
          .length;

      final totalRevenue = paymentsSnapshot.docs.fold<double>(0, (sum, doc) {
        return sum + (doc.data()['amount'] ?? 0.0);
      });

      // Activités récentes (simulation)
      _recentActivities = [
        {
          'type': 'user_registration',
          'message': 'Nouvel utilisateur inscrit',
          'time': DateTime.now().subtract(const Duration(minutes: 15)),
          'icon': Icons.person_add,
          'color': Colors.green,
        },
        {
          'type': 'course_created',
          'message': 'Nouveau cours créé par un formateur',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
          'icon': Icons.book,
          'color': Colors.blue,
        },
        {
          'type': 'payment_received',
          'message': 'Paiement Premium reçu',
          'time': DateTime.now().subtract(const Duration(hours: 3)),
          'icon': Icons.payment,
          'color': Colors.orange,
        },
        {
          'type': 'quiz_completed',
          'message': '15 quiz complétés aujourd\'hui',
          'time': DateTime.now().subtract(const Duration(hours: 4)),
          'icon': Icons.quiz,
          'color': Colors.purple,
        },
      ];

      setState(() {
        _systemStats = {
          'totalUsers': totalUsers,
          'totalStudents': totalStudents,
          'totalInstructors': totalInstructors,
          'totalCourses': totalCourses,
          'activeCourses': activeCourses,
          'totalEnrollments': enrollmentsSnapshot.docs.length,
          'totalQuizzes': quizzesSnapshot.docs.length,
          'totalRevenue': totalRevenue,
          'monthlyGrowth': 12, // Simulation
          'systemHealth': 98, // Simulation
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion Administrateur'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🔧 Administration EduBot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B1E23),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Afficher les notifications
              _showNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec salutations
                  _buildWelcomeHeader(),
                  const SizedBox(height: 24),

                  // Métriques principales
                  _buildMainMetrics(),
                  const SizedBox(height: 24),

                  // Actions rapides
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Graphiques et activités récentes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activités récentes
                      Expanded(flex: 2, child: _buildRecentActivities()),
                      const SizedBox(width: 16),
                      // Santé du système
                      Expanded(child: _buildSystemHealth()),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 30,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${widget.adminName} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Voici un aperçu de votre système EduBot',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_systemStats['systemHealth'] ?? 0}% Santé',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Utilisateurs Total',
          '${_systemStats['totalUsers'] ?? 0}',
          Icons.people,
          const Color(0xFF4F46E5),
          '+${_systemStats['monthlyGrowth'] ?? 0}% ce mois',
        ),
        _buildMetricCard(
          'Étudiants Actifs',
          '${_systemStats['totalStudents'] ?? 0}',
          Icons.school,
          const Color(0xFF059669),
          '${_systemStats['totalEnrollments'] ?? 0} inscriptions',
        ),
        _buildMetricCard(
          'Formateurs',
          '${_systemStats['totalInstructors'] ?? 0}',
          Icons.person_outline,
          const Color(0xFFDC2626),
          '${_systemStats['activeCourses'] ?? 0} cours actifs',
        ),
        _buildMetricCard(
          'Revenus',
          '${_formatCurrency(_systemStats['totalRevenue'] ?? 0)}',
          Icons.attach_money,
          const Color(0xFFF59E0B),
          'FCFA ce mois',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Gestion Utilisateurs',
              Icons.people_outline,
              const Color(0xFF8B5CF6),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersManagementPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Gestion Cours',
              Icons.book_outlined,
              const Color(0xFF06B6D4),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCoursesManagementPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Paramètres Système',
              Icons.settings_outlined,
              const Color(0xFF10B981),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSystemSettingsPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Gestion Paiements',
              Icons.payment_outlined,
              const Color(0xFFF59E0B),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPaymentsPage()),
                );
              },
            ),
            _buildActionCard(
              'Support & Rapports',
              Icons.support_agent_outlined,
              const Color(0xFFEF4444),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSupportReportsPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Analytics Avancés',
              Icons.analytics_outlined,
              const Color(0xFF6366F1),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnalyticsPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Activités Récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              return _buildActivityItem(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity['icon'], color: activity['color'], size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['message'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(activity['time']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Santé du Système',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          _buildHealthItem('Serveur', 98, Colors.green),
          const SizedBox(height: 12),
          _buildHealthItem('Base de données', 95, Colors.green),
          const SizedBox(height: 12),
          _buildHealthItem('Stockage', 87, Colors.orange),
          const SizedBox(height: 12),
          _buildHealthItem('API', 99, Colors.green),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Afficher détails système
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Voir Détails'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String name, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$percentage%', style: TextStyle(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Notifications Système'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Mise à jour disponible'),
                subtitle: const Text('Version 2.1.0 disponible'),
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.red),
                title: const Text('Alerte sécurité'),
                subtitle: const Text('3 tentatives de connexion échouées'),
              ),
              ListTile(
                leading: const Icon(Icons.storage, color: Colors.blue),
                title: const Text('Sauvegarde terminée'),
                subtitle: const Text('Sauvegarde automatique réussie'),
              ),
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

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays} jours';
    }
  }
}

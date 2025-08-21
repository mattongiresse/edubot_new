import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriod = '30 jours';
  Map<String, dynamic> _analyticsStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsStatistics();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadAnalyticsStatistics() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .get();
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .get();
      final quizAttemptsSnapshot = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .get();

      final totalUsers = usersSnapshot.docs.length;
      final activeUsers = usersSnapshot.docs
          .where(
            (doc) =>
                (doc.data()['lastLogin'] as Timestamp?)?.toDate().isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                ) ??
                false,
          )
          .length;
      final completionRate = enrollmentsSnapshot.docs.isNotEmpty
          ? (enrollmentsSnapshot.docs
                        .where((doc) => doc.data()['isCompleted'] == true)
                        .length /
                    enrollmentsSnapshot.docs.length *
                    100)
                .round()
          : 0;
      final averageQuizScore = quizAttemptsSnapshot.docs.isNotEmpty
          ? quizAttemptsSnapshot.docs.fold<double>(
                  0,
                  (sum, doc) => sum + (doc.data()['score'] ?? 0),
                ) /
                quizAttemptsSnapshot.docs.length
          : 0;

      setState(() {
        _analyticsStats = {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'completionRate': completionRate,
          'averageQuizScore': averageQuizScore.round(),
          'totalEnrollments': enrollmentsSnapshot.docs.length,
          'totalQuizzes': quizzesSnapshot.docs.length,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('📈 Analytics Avancés'),
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
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Utilisateurs', icon: Icon(Icons.people)),
            Tab(text: 'Cours & Quiz', icon: Icon(Icons.book)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _exportAnalyticsReport,
            icon: const Icon(Icons.download),
            tooltip: 'Exporter rapport',
          ),
        ],
      ),
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildCoursesQuizzesTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Utilisateurs Actifs',
                '${_analyticsStats['activeUsers']}',
                Icons.person,
                Colors.blue,
                'Derniers 30 jours',
              ),
              _buildMetricCard(
                'Taux de Complétion',
                '${_analyticsStats['completionRate']}%',
                Icons.check_circle,
                Colors.green,
                'Cours terminés',
              ),
              _buildMetricCard(
                'Score Moyen Quiz',
                '${_analyticsStats['averageQuizScore']}%',
                Icons.quiz,
                Colors.purple,
                'Sur tous les quiz',
              ),
              _buildMetricCard(
                'Inscriptions Totales',
                '${_analyticsStats['totalEnrollments']}',
                Icons.book,
                Colors.orange,
                'Tous les cours',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUserActivityChart(),
          const SizedBox(height: 24),
          _buildTopCourses(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivityChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Activité des Utilisateurs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 50),
                        const FlSpot(1, 60),
                        const FlSpot(2, 80),
                        const FlSpot(3, 70),
                        const FlSpot(4, 90),
                        const FlSpot(5, 100),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            'Jan',
                            'Fév',
                            'Mar',
                            'Avr',
                            'Mai',
                            'Jun',
                          ];
                          return Text(months[value.toInt()]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) =>
                            Text('${value.toInt()}'),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCourses() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cours Populaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .orderBy('enrollmentsCount', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Aucun cours populaire.');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.book, color: Colors.blue),
                      title: Text(data['title'] ?? 'Sans titre'),
                      subtitle: Text(
                        '${data['enrollmentsCount'] ?? 0} inscriptions',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Période',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['7 jours', '30 jours', '90 jours', 'Tous'].map((period) {
              return DropdownMenuItem(value: period, child: Text(period));
            }).toList(),
            onChanged: (value) => setState(() => _selectedPeriod = value!),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('lastLogin', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Aucun utilisateur trouvé.');
              }
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final matchesSearch =
                    data['name']?.toLowerCase().contains(_searchQuery) ?? true;
                final matchesPeriod = _filterByPeriod(
                  data['lastLogin']?.toDate(),
                );
                return matchesSearch && matchesPeriod;
              }).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(data['name'] ?? 'Anonyme'),
                    subtitle: Text(
                      'Dernière connexion: ${_formatDate(data['lastLogin']?.toDate() ?? DateTime.now())}',
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Performance des Cours & Quiz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('courses')
                .orderBy('enrollmentsCount', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Aucun cours trouvé.');
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.blue),
                    title: Text(data['title'] ?? 'Sans titre'),
                    subtitle: Text(
                      'Inscriptions: ${data['enrollmentsCount'] ?? 0} | Complétion: ${data['completionRate'] ?? 0}%',
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _filterByPeriod(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    switch (_selectedPeriod) {
      case '7 jours':
        return diff <= 7;
      case '30 jours':
        return diff <= 30;
      case '90 jours':
        return diff <= 90;
      case 'Tous':
        return true;
      default:
        return true;
    }
  }

  void _exportAnalyticsReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export du rapport analytique en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

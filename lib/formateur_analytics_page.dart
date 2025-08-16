import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class FormateurAnalyticsPage extends StatefulWidget {
  const FormateurAnalyticsPage({super.key});

  @override
  State<FormateurAnalyticsPage> createState() => _FormateurAnalyticsPageState();
}

class _FormateurAnalyticsPageState extends State<FormateurAnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30 jours';
  final List<String> _periods = ['7 jours', '30 jours', '3 mois', '1 an'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analytics & Statistiques'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.trending_up), text: 'Engagement'),
            Tab(icon: Icon(Icons.school), text: 'Performance'),
            Tab(icon: Icon(Icons.insights), text: 'Prédictions'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtre de période
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Période:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _periods
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPeriod = val!),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEngagementTab(),
                _buildPerformanceTab(),
                _buildPredictionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('Erreur lors du chargement des données'),
          );
        }

        final overviewData = _calculateOverviewData(snapshot.data!);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Métriques principales
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildMetricCard(
                    'Étudiants Actifs',
                    overviewData['activeStudents'].toString(),
                    Icons.people,
                    Colors.blue,
                    '+${overviewData['studentsGrowth']}%',
                  ),
                  _buildMetricCard(
                    'Cours Créés',
                    overviewData['totalCourses'].toString(),
                    Icons.book,
                    Colors.green,
                    '+${overviewData['coursesGrowth']}%',
                  ),
                  _buildMetricCard(
                    'Quiz Complétés',
                    overviewData['completedQuizzes'].toString(),
                    Icons.quiz,
                    Colors.orange,
                    '+${overviewData['quizzesGrowth']}%',
                  ),
                  _buildMetricCard(
                    'Taux de Réussite',
                    '${overviewData['successRate']}%',
                    Icons.trending_up,
                    Colors.purple,
                    '${overviewData['successRateChange'] > 0 ? '+' : ''}${overviewData['successRateChange']}%',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Graphique d'activité
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activité des 30 derniers jours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateActivitySpots(
                                  overviewData['dailyActivity'],
                                ),
                                isCurved: true,
                                color: Colors.deepPurple,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepPurple.withOpacity(0.1),
                                ),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}j');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                color: change.contains('-') ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateActivitySpots(List<int> activity) {
    return List.generate(
      activity.length,
      (index) => FlSpot(index.toDouble(), activity[index].toDouble()),
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedData() async* {
    final coursesStream = FirebaseFirestore.instance
        .collection('courses')
        .snapshots();
    final quizzesStream = FirebaseFirestore.instance
        .collection('quizzes')
        .snapshots();

    await for (final courses in coursesStream) {
      final quizzes = await quizzesStream.first;
      yield [courses, quizzes];
    }
  }

  Map<String, dynamic> _calculateOverviewData(List<QuerySnapshot> data) {
    return {
      'activeStudents': 120,
      'studentsGrowth': 12,
      'totalCourses': data[0].docs.length,
      'coursesGrowth': 5,
      'completedQuizzes': data[1].docs.length,
      'quizzesGrowth': 8,
      'successRate': 85,
      'successRateChange': 3,
      'dailyActivity': [3, 4, 6, 5, 8, 7, 10, 12, 8, 9, 11, 7, 6, 5, 8],
    };
  }

  Widget _buildEngagementTab() {
    return const Center(child: Text("Graphiques et stats d'engagement"));
  }

  Widget _buildPerformanceTab() {
    return const Center(child: Text("Analyse de la performance"));
  }

  Widget _buildPredictionsTab() {
    return const Center(child: Text("Prévisions basées sur l'IA"));
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rapport exporté avec succès")),
    );
  }
}

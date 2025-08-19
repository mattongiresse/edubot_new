import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminSupportReportsPage extends StatefulWidget {
  const AdminSupportReportsPage({super.key});

  @override
  State<AdminSupportReportsPage> createState() =>
      _AdminSupportReportsPageState();
}

class _AdminSupportReportsPageState extends State<AdminSupportReportsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriod = '30 jours';
  String _selectedStatus = 'Tous'; // Ajout de l'initialisation
  bool _isLoadingStats = true;
  Map<String, dynamic> _supportStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSupportStatistics();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadSupportStatistics() async {
    try {
      final incidentsSnapshot = await FirebaseFirestore.instance
          .collection('support_tickets')
          .get();

      final resolvedTickets = incidentsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'Résolu')
          .length;

      setState(() {
        _supportStats = {
          'totalTickets': incidentsSnapshot.docs.length,
          'openTickets': incidentsSnapshot.docs
              .where((doc) => doc.data()['status'] == 'Ouvert')
              .length,
          'resolvedTickets': resolvedTickets,
          'averageResolutionTime': 2.5, // En jours
          'userSatisfaction': 85, // En pourcentage
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
        title: const Text('📞 Support & Rapports'),
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
            Tab(text: 'Incidents', icon: Icon(Icons.report_problem)),
            Tab(text: 'Rapports', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _exportSupportReport,
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
                _buildIncidentsTab(),
                _buildReportsTab(),
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
          // Métriques principales
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Total Incidents',
                '${_supportStats['totalTickets']}',
                Icons.report_problem,
                Colors.red,
                '${_supportStats['openTickets']} ouverts',
              ),
              _buildMetricCard(
                'Tickets Résolus',
                '${_supportStats['resolvedTickets']}',
                Icons.check_circle,
                Colors.green,
                'Ce mois',
              ),
              _buildMetricCard(
                'Temps de Résolution',
                '${_supportStats['averageResolutionTime']} jours',
                Icons.timer,
                Colors.blue,
                'Moyenne',
              ),
              _buildMetricCard(
                'Satisfaction',
                '${_supportStats['userSatisfaction']}%',
                Icons.sentiment_satisfied,
                Colors.purple,
                'Utilisateurs',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Graphique des incidents
          _buildIncidentsChart(),
          const SizedBox(height: 24),
          // Tickets récents
          _buildRecentTickets(),
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

  Widget _buildIncidentsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Évolution des Incidents',
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
                        const FlSpot(0, 20),
                        const FlSpot(1, 25),
                        const FlSpot(2, 18),
                        const FlSpot(3, 30),
                        const FlSpot(4, 22),
                        const FlSpot(5, 15),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
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

  Widget _buildRecentTickets() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tickets Récents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_tickets')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Aucun ticket récent.');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(
                        _getStatusIcon(data['status']),
                        color: _getStatusColor(data['status']),
                      ),
                      title: Text(data['title'] ?? 'Sans titre'),
                      subtitle: Text(
                        'Par ${data['userName'] ?? 'Anonyme'} - ${_formatDate(data['createdAt']?.toDate() ?? DateTime.now())}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleTicketAction(value, doc.id),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('Voir détails'),
                          ),
                          const PopupMenuItem(
                            value: 'resolve',
                            child: Text('Marquer comme résolu'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
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

  Widget _buildIncidentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher un ticket...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    labelText: 'Période',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['7 jours', '30 jours', '90 jours', 'Tous'].map((
                    period,
                  ) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedPeriod = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Tous', 'Ouvert', 'Résolu', 'En attente'].map((
                    status,
                  ) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStatus = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('support_tickets')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Aucun ticket trouvé.');
              }
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final matchesSearch =
                    data['title']?.toLowerCase().contains(_searchQuery) ?? true;
                final matchesStatus =
                    _selectedStatus == 'Tous' ||
                    data['status'] == _selectedStatus;
                final matchesPeriod = _filterByPeriod(
                  data['createdAt']?.toDate(),
                );
                return matchesSearch && matchesStatus && matchesPeriod;
              }).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(
                      _getStatusIcon(data['status']),
                      color: _getStatusColor(data['status']),
                    ),
                    title: Text(data['title'] ?? 'Sans titre'),
                    subtitle: Text(
                      'Par ${data['userName'] ?? 'Anonyme'} - ${_formatDate(data['createdAt']?.toDate() ?? DateTime.now())}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleTicketAction(value, filteredDocs[index].id),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Text('Voir détails'),
                        ),
                        const PopupMenuItem(
                          value: 'resolve',
                          child: Text('Marquer comme résolu'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
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

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Générer des Rapports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _generateUsageReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rapport d\'Utilisation Mensuel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _generateAnnualReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rapport Annuel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Rapports Récents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: const Text('Rapport Mensuel - Sept 2025'),
            subtitle: const Text('Généré le 01/10/2025'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportSupportReport,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: const Text('Rapport Annuel - 2024'),
            subtitle: const Text('Généré le 01/01/2025'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportSupportReport,
            ),
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

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Ouvert':
        return Icons.error_outline;
      case 'Résolu':
        return Icons.check_circle;
      case 'En attente':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Ouvert':
        return Colors.red;
      case 'Résolu':
        return Colors.green;
      case 'En attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleTicketAction(String action, String ticketId) {
    switch (action) {
      case 'details':
        _showTicketDetails(ticketId);
        break;
      case 'resolve':
        _resolveTicket(ticketId);
        break;
      case 'delete':
        _deleteTicket(ticketId);
        break;
    }
  }

  void _showTicketDetails(String ticketId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket $ticketId'),
        content: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('support_tickets')
              .doc(ticketId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Titre: ${data['title'] ?? 'Sans titre'}'),
                Text('Utilisateur: ${data['userName'] ?? 'Anonyme'}'),
                Text('Statut: ${data['status'] ?? 'Inconnu'}'),
                Text(
                  'Date: ${_formatDate(data['createdAt']?.toDate() ?? DateTime.now())}',
                ),
                const SizedBox(height: 8),
                Text('Description: ${data['description'] ?? 'Aucune'}'),
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

  void _resolveTicket(String ticketId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résoudre le Ticket'),
        content: Text('Marquer le ticket $ticketId comme résolu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('support_tickets')
                  .doc(ticketId)
                  .update({'status': 'Résolu'});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket marqué comme résolu'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Résoudre'),
          ),
        ],
      ),
    );
  }

  void _deleteTicket(String ticketId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Ticket'),
        content: Text('Supprimer définitivement le ticket $ticketId ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('support_tickets')
                  .doc(ticketId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket supprimé'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _exportSupportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export du rapport de support en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateUsageReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport d\'utilisation mensuel...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateAnnualReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport annuel...'),
        backgroundColor: Colors.green,
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

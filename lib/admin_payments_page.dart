import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriod = '30 jours';
  String _selectedStatus = 'Tous';

  Map<String, dynamic> _paymentStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPaymentStatistics();
  }

  Future<void> _loadPaymentStatistics() async {
    try {
      // Récupérer les statistiques depuis Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('payment_stats')
          .doc('summary')
          .get();

      if (snapshot.exists) {
        setState(() {
          _paymentStats = snapshot.data() ?? {};
          _isLoadingStats = false;
        });
      } else {
        // Données par défaut si pas de document
        setState(() {
          _paymentStats = {
            'totalRevenue': 2450000,
            'monthlyRevenue': 850000,
            'totalTransactions': 1250,
            'successfulTransactions': 1180,
            'failedTransactions': 70,
            'averageTransactionAmount': 1960,
            'topPaymentMethod': 'Mobile Money',
            'conversionRate': 94.4,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingStats = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('💳 Gestion des Paiements'),
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
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Abonnements', icon: Icon(Icons.subscriptions)),
            Tab(text: 'Rapports', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _exportPaymentReport,
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
                _buildTransactionsTab(),
                _buildSubscriptionsTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
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
                'Revenus Totaux',
                '${_formatCurrency(_paymentStats['totalRevenue'] ?? 0)}',
                Icons.account_balance_wallet,
                Colors.green,
                '+12% ce mois',
              ),
              _buildMetricCard(
                'Revenus Mensuels',
                '${_formatCurrency(_paymentStats['monthlyRevenue'] ?? 0)}',
                Icons.trending_up,
                Colors.blue,
                'Ce mois-ci',
              ),
              _buildMetricCard(
                'Transactions',
                '${_paymentStats['totalTransactions'] ?? 0}',
                Icons.receipt,
                Colors.orange,
                '${_paymentStats['successfulTransactions'] ?? 0} réussies',
              ),
              _buildMetricCard(
                'Taux de Conversion',
                '${(_paymentStats['conversionRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.show_chart,
                Colors.purple,
                'En amélioration',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Graphique des revenus
          Row(
            children: [
              Expanded(flex: 2, child: _buildRevenueChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildPaymentMethodsChart()),
            ],
          ),

          const SizedBox(height: 24),

          // Transactions récentes
          _buildRecentTransactions(),
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

  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Évolution des Revenus',
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
                        const FlSpot(0, 300000),
                        const FlSpot(1, 450000),
                        const FlSpot(2, 520000),
                        const FlSpot(3, 680000),
                        const FlSpot(4, 750000),
                        const FlSpot(5, 850000),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
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
                        getTitlesWidget: (value, meta) {
                          return Text('${(value / 1000).toInt()}k');
                        },
                      ),
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
    );
  }

  Widget _buildPaymentMethodsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💳 Méthodes de Paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 60,
                      title: '60%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: 30,
                      title: '30%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 10,
                      title: '10%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildLegendItem('Mobile Money', Colors.blue),
                _buildLegendItem('Orange Money', Colors.orange),
                _buildLegendItem('Carte Bancaire', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔄 Transactions Récentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final data =
                        transactions[index].data() as Map<String, dynamic>;
                    return _buildTransactionItem(
                      data['userId'] ?? 'user_${index + 1}',
                      data['userName'] ?? 'Utilisateur ${index + 1}',
                      (data['amount'] ?? 2000) as int,
                      (data['timestamp'] ?? Timestamp.now()).toDate(),
                      data['status'] ?? 'Réussie',
                      data['method'] ?? 'Mobile Money',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Filtres
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
                        hintText: 'Rechercher par utilisateur, ID...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown(
                    'Status',
                    _selectedStatus,
                    ['Tous', 'Réussie', 'En attente', 'Échouée', 'Remboursée'],
                    (value) => setState(() => _selectedStatus = value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterDropdown(
                    'Période',
                    _selectedPeriod,
                    ['7 jours', '30 jours', '3 mois', '6 mois', '1 an'],
                    (value) => setState(() => _selectedPeriod = value),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _exportTransactions,
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Liste des transactions
        Expanded(child: _buildTransactionsList()),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where(
            'status',
            isEqualTo: _selectedStatus != 'Tous' ? _selectedStatus : null,
          )
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var transactions = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          transactions = transactions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['userName']?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (data['transactionId']?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
          }).toList();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final data = transactions[index].data() as Map<String, dynamic>;
            return _buildTransactionCard(
              data['transactionId'] ?? 'TX${1000 + index}',
              data['userName'] ?? 'Utilisateur ${index + 1}',
              (data['amount'] ?? 2000 + (index * 100)) as int,
              (data['timestamp'] ?? Timestamp.now()).toDate(),
              data['status'] ??
                  (index % 4 == 0
                      ? 'Échouée'
                      : index % 3 == 0
                      ? 'En attente'
                      : 'Réussie'),
              data['method'] ??
                  (index % 2 == 0 ? 'Mobile Money' : 'Orange Money'),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(
    String transactionId,
    String userName,
    int amount,
    DateTime date,
    String status,
    String method,
  ) {
    Color statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(status), color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: $transactionId',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              method,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('Voir détails'),
                ],
              ),
            ),
            if (status == 'En attente')
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Annuler'),
                  ],
                ),
              ),
            if (status == 'Réussie')
              const PopupMenuItem(
                value: 'refund',
                child: Row(
                  children: [
                    Icon(Icons.undo, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Rembourser'),
                  ],
                ),
              ),
          ],
          onSelected: (value) => _handleTransactionAction(value, transactionId),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    String userId,
    String userName,
    int amount,
    DateTime date,
    String status,
    String method,
  ) {
    Color statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            radius: 20,
            child: Icon(_getStatusIcon(status), color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$method • ${_formatDate(date)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Statistiques abonnements
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Abonnés Actifs',
                '1,247',
                Icons.people,
                Colors.green,
                '+15% ce mois',
              ),
              _buildMetricCard(
                'Churn Rate',
                '2.3%',
                Icons.trending_down,
                Colors.red,
                'En amélioration',
              ),
              _buildMetricCard(
                'MRR',
                '${_formatCurrency(1850000)}',
                Icons.attach_money,
                Colors.blue,
                'Revenus récurrents',
              ),
              _buildMetricCard(
                'Taux Conversion',
                '18.5%',
                Icons.transform,
                Colors.purple,
                'Essai → Premium',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Plans d'abonnement
          _buildSubscriptionPlans(),

          const SizedBox(height: 24),

          // Abonnés récents
          _buildRecentSubscribers(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📋 Plans d\'Abonnement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddPlanDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subscription_plans')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final plans = snapshot.data!.docs;
                return Column(
                  children: plans.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildPlanCard(
                      data['name'] ?? 'Plan inconnu',
                      '${_formatCurrency(data['price'] ?? 0)}',
                      data['description'] ?? 'Aucune description',
                      data['subscribers'] ?? 0,
                      _getPlanColor(data['name'] ?? ''),
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

  Widget _buildPlanCard(
    String name,
    String price,
    String description,
    int subscribers,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(description, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              Text(
                '$subscribers abonnés',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
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
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('Statistiques'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(String name) {
    switch (name.toLowerCase()) {
      case 'mensuel':
        return Colors.blue;
      case 'trimestriel':
        return Colors.green;
      case 'semestriel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentSubscribers() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 Nouveaux Abonnés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subscribers')
                  .orderBy('subscriptionDate', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subscribers = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subscribers.length,
                  itemBuilder: (context, index) {
                    final data =
                        subscribers[index].data() as Map<String, dynamic>;
                    return _buildSubscriberItem(
                      data['userName'] ?? 'Utilisateur ${index + 1}',
                      data['plan'] ??
                          (index % 3 == 0
                              ? 'Mensuel'
                              : index % 2 == 0
                              ? 'Trimestriel'
                              : 'Semestriel'),
                      (data['subscriptionDate'] ?? Timestamp.now()).toDate(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriberItem(
    String userName,
    String plan,
    DateTime subscriptionDate,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Plan $plan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(subscriptionDate),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Actions de rapport
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateMonthlyReport,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Rapport Mensuel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateYearlyReport,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Rapport Annuel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rapports automatisés
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Rapports Automatisés',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildReportItem(
                    'Rapport Quotidien',
                    'Généré automatiquement à 23h59',
                    Icons.today,
                    Colors.blue,
                    true,
                  ),
                  _buildReportItem(
                    'Rapport Hebdomadaire',
                    'Tous les lundis à 8h00',
                    Icons.date_range,
                    Colors.green,
                    true,
                  ),
                  _buildReportItem(
                    'Rapport Mensuel',
                    'Le 1er de chaque mois',
                    Icons.calendar_month,
                    Colors.orange,
                    false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Analyse des tendances
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📈 Analyse des Tendances',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTrendItem(
                    'Revenus',
                    '+23%',
                    'vs mois dernier',
                    Colors.green,
                    true,
                  ),
                  _buildTrendItem(
                    'Nouveaux abonnés',
                    '+15%',
                    'vs mois dernier',
                    Colors.blue,
                    true,
                  ),
                  _buildTrendItem(
                    'Taux de churn',
                    '-5%',
                    'amélioration',
                    Colors.orange,
                    false,
                  ),
                  _buildTrendItem(
                    'Panier moyen',
                    '+8%',
                    'augmentation',
                    Colors.purple,
                    true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String schedule,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  schedule,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) {
              setState(() {
                // Logique pour activer/désactiver le rapport (simulée ici)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rapport $title ${value ? "activé" : "désactivé"}',
                    ),
                  ),
                );
              });
            },
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
    String metric,
    String change,
    String period,
    Color color,
    bool isPositive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metric,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                change,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                period,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (newValue) => onChanged(newValue!),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Réussie':
        return Colors.green;
      case 'En attente':
        return Colors.orange;
      case 'Échouée':
        return Colors.red;
      case 'Remboursée':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Réussie':
        return Icons.check_circle;
      case 'En attente':
        return Icons.pending;
      case 'Échouée':
        return Icons.error;
      case 'Remboursée':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }

  void _handleTransactionAction(String action, String transactionId) {
    switch (action) {
      case 'details':
        _showTransactionDetails(transactionId);
        break;
      case 'cancel':
        _cancelTransaction(transactionId);
        break;
      case 'refund':
        _refundTransaction(transactionId);
        break;
    }
  }

  void _showTransactionDetails(String transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction $transactionId'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Utilisateur: Jean Dupont'),
            Text('Montant: 2000 FCFA'),
            Text('Méthode: Mobile Money'),
            Text('Date: 15/12/2024 14:30'),
            Text('Status: Réussie'),
            Text('ID de référence: MM123456789'),
          ],
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

  void _cancelTransaction(String transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler Transaction'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler la transaction $transactionId ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('transactions')
                  .doc(transactionId)
                  .update({'status': 'Annulée'});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction annulée'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  void _refundTransaction(String transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rembourser Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rembourser la transaction $transactionId ?'),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Motif du remboursement',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
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
              FirebaseFirestore.instance
                  .collection('transactions')
                  .doc(transactionId)
                  .update({'status': 'Remboursée'});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Remboursement initié'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Rembourser'),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog() {
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    final _durationController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Plan d\'Abonnement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du plan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée (jours)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final planData = {
                'name': _nameController.text,
                'price': int.tryParse(_priceController.text) ?? 0,
                'duration': int.tryParse(_durationController.text) ?? 0,
                'description': _descriptionController.text,
                'subscribers': 0,
              };
              FirebaseFirestore.instance
                  .collection('subscription_plans')
                  .add(planData);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan créé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _exportPaymentReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export du rapport de paiements en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
    // Logique d'exportation (par ex. générer un fichier CSV)
  }

  void _exportTransactions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des transactions en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
    // Logique d'exportation avec filtres
  }

  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport mensuel...'),
        backgroundColor: Colors.blue,
      ),
    );
    // Logique pour générer un rapport mensuel
  }

  void _generateYearlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport annuel...'),
        backgroundColor: Colors.green,
      ),
    );
    // Logique pour générer un rapport annuel
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} FCFA';
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FormateurProfilePage extends StatefulWidget {
  const FormateurProfilePage({super.key});

  @override
  State<FormateurProfilePage> createState() => _FormateurProfilePageState();
}

class _FormateurProfilePageState extends State<FormateurProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specialitesController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Switch settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _weeklyReports = false;
  bool _newEnrollmentNotifs = true;
  bool _quizSubmissionNotifs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Simuler des données utilisateur
    _prenomController.text = " ";
    _nomController.text = " ";
    _emailController.text = " ";
    _bioController.text = " ";
    _specialitesController.text = " ";
    _experienceController.text = " ";
    _linkedinController.text = " ";
    _websiteController.text = " ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mon Profil Formateur"),
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
            Tab(icon: Icon(Icons.person), text: "Profil"),
            Tab(icon: Icon(Icons.work), text: "Professionnel"),
            Tab(icon: Icon(Icons.settings), text: "Parametres"),
            Tab(icon: Icon(Icons.bar_chart), text: "Mes Stats"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildProfessionalTab(),
          _buildSettingsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  /// Onglet Profil
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar + bouton changer photo
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/profile_placeholder.png"),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _changeProfilePicture,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Champs infos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prenomController,
                          decoration: const InputDecoration(
                            labelText: 'Prenom',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      suffixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Biographie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      hintText:
                          'Parlez-nous de votre parcours et votre passion pour l\'enseignement...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Professionnel
  Widget _buildProfessionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Expérience
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.work, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Expérience Professionnelle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _specialitesController,
                    decoration: const InputDecoration(
                      labelText: 'Spécialité',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.stars),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _experienceController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Expériance détaillée',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history_edu),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Liens professionnels
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Liens Professionnels",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _linkedinController,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_center),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Site Web ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.web),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Certifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            "Certifications",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCertification,
                        icon: const Icon(Icons.add),
                        label: const Text("Ajouter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildCertificationItem(
                    "Flutter Developer Certification",
                    "Google",
                    "2024",
                    Icons.verified,
                    Colors.blue,
                  ),
                  _buildCertificationItem(
                    "Firebase Expert",
                    "Google Cloud",
                    "2023",
                    Icons.cloud,
                    Colors.orange,
                  ),
                  _buildCertificationItem(
                    "Pédagoge Numérque",
                    "Université de Yaoundé",
                    "2022",
                    Icons.school,
                    Colors.purple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Paramètres
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text("Notifications Email"),
                    value: _emailNotifications,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                  ),
                  SwitchListTile(
                    title: const Text("Notifications Push"),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  SwitchListTile(
                    title: const Text("Rapports hebdomadaires"),
                    value: _weeklyReports,
                    onChanged: (v) => setState(() => _weeklyReports = v),
                  ),
                  SwitchListTile(
                    title: const Text("Nouvelles inscriptions"),
                    value: _newEnrollmentNotifs,
                    onChanged: (v) => setState(() => _newEnrollmentNotifs = v),
                  ),
                  SwitchListTile(
                    title: const Text("Quiz soumis"),
                    value: _quizSubmissionNotifs,
                    onChanged: (v) => setState(() => _quizSubmissionNotifs = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confidentialité
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Confidentialité",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.visibility),
                    title: const Text("Profil public"),
                    trailing: Switch(value: true, onChanged: (v) {}),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text("Statistiques publiques"),
                    trailing: Switch(value: false, onChanged: (v) {}),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contact_mail),
                    title: const Text("Contact direct"),
                    trailing: Switch(value: true, onChanged: (v) {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions de compte
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_circle, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Actions de Compte",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock),
                    label: const Text("Changer le mot de passe"),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text("Exporter mes données"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Se déconnecter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete),
                    label: const Text("Supprimer mon compte"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet Stats
  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistiques d'enseignement",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5),
                      FlSpot(1, 7),
                      FlSpot(2, 9),
                      FlSpot(3, 6),
                      FlSpot(4, 10),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.deepPurple,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepPurple.withOpacity(0.2),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text("S${v.toInt()}"),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widgets utilitaires
  Widget _buildCertificationItem(
    String title,
    String issuer,
    String year,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text("$issuer - $year"),
      trailing: const Icon(Icons.more_vert),
    );
  }

  /// Actions
  void _addCertification() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ajouter certification")));
  }

  void _changeProfilePicture() {}
  void _changePassword() {}
  void _exportData() {}
  void _deleteAccount() {}

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fermer la dialog
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fermer la dialog
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _specialitesController.dispose();
    _experienceController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}

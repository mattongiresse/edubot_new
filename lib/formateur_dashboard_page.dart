import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormateurDashboardPage extends StatelessWidget {
  final String userName;

  const FormateurDashboardPage({super.key, required this.userName});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 141, 145, 151),
      appBar: AppBar(
        title: const Text(
          'Dashboard Formateur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 En-tête de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Bienvenue, $userName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Espace Formateur',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 📊 Cartes de fonctionnalités (provisoires)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildFeatureCard(
                    icon: Icons.analytics,
                    title: 'Statistiques',
                    subtitle: 'Performance étudiants',
                    color: Colors.blue,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildFeatureCard(
                    icon: Icons.book,
                    title: 'Mes Cours',
                    subtitle: 'Gestion du contenu',
                    color: Colors.green,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Étudiants',
                    subtitle: 'Gestion des apprenants',
                    color: Colors.orange,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildFeatureCard(
                    icon: Icons.assignment,
                    title: 'Évaluations',
                    subtitle: 'Quiz & examens',
                    color: Colors.red,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildFeatureCard(
                    icon: Icons.chat,
                    title: 'Messages',
                    subtitle: 'Communication',
                    color: Colors.teal,
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildFeatureCard(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    subtitle: 'Configuration',
                    color: Colors.grey,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 10),
            Text('Bientôt disponible'),
          ],
        ),
        content: const Text(
          'Cette fonctionnalité sera ajoutée dans une prochaine version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

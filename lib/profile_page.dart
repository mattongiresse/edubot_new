import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = true; // État initial pour le thème sombre
  bool _isNotificationsEnabled = true; // État initial pour les notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- EN-TÊTE AVEC NOM ET EMAIL ---
          ListTile(
            leading: CircleAvatar(
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
            title: Text(
              widget.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: const Text(
              "user@example.com",
            ), // Remplacez par l'email réel si disponible
          ),
          const Divider(),
          // --- APPEARANCE ---
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Apparence'),
            subtitle: const Text('Thème sombre'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                });
              },
              activeColor: Colors.deepPurple,
            ),
          ),
          // --- ABONNEMENT ---
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Abonnement'),
            subtitle: const Text('Plan d\'abonnement'),
            onTap: () {
              // Placeholder pour ouvrir le dialogue de paiement si nécessaire
            },
          ),
          // --- PARAMÈTRES ---
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: _isNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                  },
                  activeColor: Colors.deepPurple,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Langue'),
              ),
            ],
          ),
          // --- AIDE ET SUPPORT TECHNIQUE ---
          const ListTile(
            leading: Icon(Icons.headset_mic),
            title: Text('Aide et Support Technique'),
            subtitle: Text('Support Technique'),
          ),
          const ListTile(leading: Icon(Icons.help), title: Text('Aide')),
          // --- DÉCONNEXION ---
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // Logique de déconnexion (par ex. avec Firebase Auth)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Déconnexion en cours..."),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

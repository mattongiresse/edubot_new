import 'package:edubot_new/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class ProfilePage extends StatefulWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = true;
  bool _isNotificationsEnabled = true;

  String _displayName = '';
  String _displayEmail = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  Future<void> _checkAuthAndFetchData() async {
    final user = FirebaseAuth.instance.currentUser;

    // Si aucun utilisateur connecté → redirection
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // Utilisateur connecté → récupérer les infos Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _displayName = doc.data()?['name'] ?? widget.userName;
        _displayEmail =
            doc.data()?['email'] ?? user.email ?? 'user@example.com';
      });
    } catch (e) {
      // En cas d’erreur de lecture Firestore
      if (!mounted) return;
      setState(() {
        _displayName = widget.userName;
        _displayEmail = user.email ?? 'user@example.com';
      });
    }
  }

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
                (_displayName.isNotEmpty
                    ? _displayName[0].toUpperCase()
                    : widget.userName[0].toUpperCase()),
                style: const TextStyle(fontSize: 40.0),
              ),
            ),
            title: Text(
              _displayName.isNotEmpty ? _displayName : widget.userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text(
              _displayEmail.isNotEmpty ? _displayEmail : "user@example.com",
            ),
          ),
          const Divider(),
          // --- APPEARANCE ---
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Apparence'),
            subtitle: const Text('Thème sombre'),
            trailing: Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) {
                    themeNotifier.toggleTheme();
                    setState(() {
                      _isDarkTheme = value;
                    });
                  },
                  activeColor: Colors.deepPurple,
                );
              },
            ),
          ),
          // --- ABONNEMENT ---
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('Abonnement'),
            subtitle: const Text('Plan d\'abonnement'),
            onTap: () {
              // Action d'abonnement
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
              const ListTile(
                leading: Icon(Icons.language),
                title: Text('Langue'),
              ),
            ],
          ),
          // --- AIDE ET SUPPORT ---
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
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

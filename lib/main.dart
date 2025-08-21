import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart'; // Ajouté
import 'formateur_profile_page.dart'; // Ajouté
import 'firebase_options.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.themeData,
            // Définition des routes
            initialRoute: '/login', // Route initiale
            routes: {
              '/login': (context) =>
                  const LoginPage(), // Route pour la page de connexion
              '/admin': (context) => const AdminDashboardPage(
                adminName: 'Admin',
              ), // Route pour le dashboard admin
              '/formateur': (context) =>
                  const FormateurProfilePage(), // Route pour le profil formateur
            },
            // Gestionnaire de routes dynamiques (optionnel)
            onGenerateRoute: (settings) {
              // Ajouter ici si tu as besoin de routes dynamiques
              return null;
            },
            // Gestionnaire de routes inconnues (optionnel)
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Route non trouvée : ${settings.name}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

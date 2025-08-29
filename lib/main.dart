import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'formateur_profile_page.dart';
import 'firebase_options.dart';
import 'theme_notifier.dart';
import 'supabase_config.dart'; // Import de la configuration Supabase
import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser Supabase
  await SupabaseConfig.initialize();

  // Initialiser Gemini
  Gemini.init(apiKey: 'AIzaSyDIl3JWgAuL_EOxJBUp8qgLdNMqxxlGZvU');

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
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginPage(),
              '/admin': (context) =>
                  const AdminDashboardPage(adminName: 'Admin'),
              '/formateur': (context) => const FormateurProfilePage(),
            },
            // Gestionnaire de routes dynamiques (optionnel)
            onGenerateRoute: (settings) {
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

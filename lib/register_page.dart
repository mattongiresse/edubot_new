import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'formateur_dashboard_page.dart'; // Import corrigé

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String nom = '',
      prenom = '',
      email = '',
      password = '',
      confirmPassword = '',
      statut = 'Étudiant';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Création du compte Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Création automatique du document Firestore avec le rôle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'nom': nom,
              'prenom': prenom,
              'email': email,
              'statut': statut,
              'createdAt': FieldValue.serverTimestamp(),
            });

        String userName = '$prenom $nom';

        // Redirection selon le rôle avec les bons constructeurs
        if (!mounted) return;
        if (statut == 'Formateur') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FormateurDashboardPage(userName: userName),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomePage(userName: userName, userRole: statut),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erreur lors de linscription')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 137, 140, 143),
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nom
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => nom = val),
                validator: (val) => val!.isEmpty ? 'Entrez votre nom' : null,
              ),
              const SizedBox(height: 15),

              // Prénom
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => prenom = val),
                validator: (val) => val!.isEmpty ? 'Entrez votre prénom' : null,
              ),
              const SizedBox(height: 15),

              // Statut
              DropdownButtonFormField<String>(
                value: statut,
                items: const [
                  DropdownMenuItem(value: 'Étudiant', child: Text('Étudiant')),
                  DropdownMenuItem(
                    value: 'Formateur',
                    child: Text('Formateur'),
                  ),
                ],
                onChanged: (val) => setState(() => statut = val!),
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                ),
                onChanged: (val) => setState(() => email = val),
                validator: (val) {
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (val == null || val.isEmpty) return 'Entrez un email';
                  if (!emailRegex.hasMatch(val)) return 'Format email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Mot de passe
              TextFormField(
                style: const TextStyle(color: Colors.black),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (val) => setState(() => password = val),
                validator: (val) =>
                    val!.length < 6 ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 15),

              // Confirmation mot de passe
              TextFormField(
                style: const TextStyle(color: Colors.black),
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer mot de passe',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => confirmPassword = val),
                validator: (val) => val != password
                    ? 'Les mots de passe ne correspondent pas'
                    : null,
              ),
              const SizedBox(height: 25),

              // Bouton inscription
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'S\'inscrire',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Déjà un compte ? Se connecter',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

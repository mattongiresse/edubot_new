import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        // Création compte Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Sauvegarde infos dans Firestore
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Inscription réussie')));
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erreur lors de l’inscription')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => nom = val),
                validator: (val) => val!.isEmpty ? 'Entrez votre nom' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => prenom = val),
                validator: (val) => val!.isEmpty ? 'Entrez votre prénom' : null,
              ),
              const SizedBox(height: 15),
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
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
              TextFormField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              TextFormField(
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('S’inscrire', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

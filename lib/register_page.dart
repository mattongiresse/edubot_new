import 'package:flutter/material.dart';

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
  DateTime? dateNaissance;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              TextFormField(
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 6570),
                    ),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => dateNaissance = date);
                },
                controller: TextEditingController(
                  text: dateNaissance != null
                      ? '${dateNaissance!.day}/${dateNaissance!.month}/${dateNaissance!.year}'
                      : '',
                ),
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (val) => dateNaissance == null
                    ? 'Sélectionnez votre date de naissance'
                    : null,
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inscription réussie')),
                    );
                    Navigator.pop(context);
                  }
                },
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

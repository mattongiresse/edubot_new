// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CoursePage extends StatefulWidget {
//   const CoursePage({super.key});

//   @override
//   _CoursePageState createState() => _CoursePageState();
// }

// class _CoursePageState extends State<CoursePage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _courseTitleController = TextEditingController();
//   final TextEditingController _courseDescriptionController =
//       TextEditingController();
//   String _selectedCategory = 'Informatique';

//   bool? _isInstructor; // null = en cours de chargement

//   @override
//   void initState() {
//     super.initState();
//     _checkInstructorStatus();
//   }

//   Future<void> _checkInstructorStatus() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       final statut = doc.data()?['statut'];
//       setState(() {
//         _isInstructor = (statut == 'Formateur');
//       });
//     } else {
//       setState(() {
//         _isInstructor = false;
//       });
//     }
//   }

//   Future<void> _addCourse() async {
//     if (_formKey.currentState!.validate()) {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await FirebaseFirestore.instance.collection('courses').add({
//           'title': _courseTitleController.text,
//           'description': _courseDescriptionController.text,
//           'category': _selectedCategory,
//           'instructorId': user.uid,
//           'createdAt': FieldValue.serverTimestamp(),
//           'isPremium': false, // Par défaut, non Premium
//         });
//         _courseTitleController.clear();
//         _courseDescriptionController.clear();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Cours ajouté avec succès')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isInstructor == null) {
//       // En cours de chargement des infos utilisateur
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mes Cours'),
//         backgroundColor: const Color.fromARGB(255, 119, 95, 161),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Liste des cours inscrits
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('courses')
//                     .orderBy('createdAt', descending: true)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   final courses = snapshot.data!.docs;
//                   return ListView.builder(
//                     itemCount: courses.length,
//                     itemBuilder: (context, index) {
//                       final course = courses[index];
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         child: ListTile(
//                           leading: const Icon(Icons.book, color: Colors.black),
//                           title: Text(
//                             course['title'],
//                             style: const TextStyle(color: Colors.black),
//                           ),
//                           subtitle: Text(
//                             course['description'],
//                             style: const TextStyle(color: Colors.black),
//                           ),
//                           trailing: ElevatedButton(
//                             onPressed: () {
//                               // Logique d'inscription (à implémenter)
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Inscription en cours...'),
//                                 ),
//                               );
//                             },
//                             child: const Text('S’inscrire'),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             // Section pour ajouter un cours (visible seulement pour le formateur)
//             if (_isInstructor!)
//               Card(
//                 margin: const EdgeInsets.only(top: 16),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         TextFormField(
//                           controller: _courseTitleController,
//                           style: const TextStyle(color: Colors.black),
//                           decoration: const InputDecoration(
//                             labelText: 'Titre du cours',
//                             labelStyle: TextStyle(color: Colors.black),
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (val) =>
//                               val!.isEmpty ? 'Entrez un titre' : null,
//                         ),
//                         const SizedBox(height: 10),
//                         TextFormField(
//                           controller: _courseDescriptionController,
//                           style: const TextStyle(color: Colors.black),
//                           decoration: const InputDecoration(
//                             labelText: 'Description',
//                             labelStyle: TextStyle(color: Colors.black),
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (val) =>
//                               val!.isEmpty ? 'Entrez une description' : null,
//                         ),
//                         const SizedBox(height: 10),
//                         DropdownButtonFormField<String>(
//                           value: _selectedCategory,
//                           items: const [
//                             DropdownMenuItem(
//                               value: 'Informatique',
//                               child: Text('Informatique'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'Mathématiques',
//                               child: Text('Mathématiques'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'Sciences',
//                               child: Text('Sciences'),
//                             ),
//                           ],
//                           onChanged: (val) =>
//                               setState(() => _selectedCategory = val!),
//                           decoration: const InputDecoration(
//                             labelText: 'Catégorie',
//                             labelStyle: TextStyle(color: Colors.black),
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _addCourse,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                           ),
//                           child: const Text('Ajouter le cours'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

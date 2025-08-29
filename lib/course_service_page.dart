// // course_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';

// class CourseService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseStorage _storage = FirebaseStorage.instance;
//   static final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Modèle de cours
//   static Map<String, dynamic> createCourseModel({
//     required String title,
//     required String description,
//     required String category,
//     required String pdfUrl,
//     required String fileName,
//     required int fileSize,
//     required String formateurId,
//     required String formateurNom,
//   }) {
//     return {
//       'title': title,
//       'description': description,
//       'category': category,
//       'pdfUrl': pdfUrl,
//       'fileName': fileName,
//       'fileSize': fileSize,
//       'formateurId': formateurId,
//       'formateurNom': formateurNom,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//       'isActive': true,
//       'likes': 0,
//       'enrollmentCount': 0,
//       'downloadCount': 0,
//     };
//   }

//   // Upload PDF vers Firebase Storage
//   static Future<String?> uploadPdfFile(
//     PlatformFile pdfFile,
//     String courseTitle,
//   ) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('Utilisateur non connecté');

//       // Créer un nom de fichier unique
//       final cleanTitle = courseTitle
//           .replaceAll(' ', '_')
//           .replaceAll(RegExp(r'[^\w\-_.]'), '');
//       final fileName =
//           'courses/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$cleanTitle.pdf';

//       final storageRef = _storage.ref().child(fileName);

//       UploadTask uploadTask;

//       if (kIsWeb) {
//         // Pour le web, utiliser bytes
//         if (pdfFile.bytes == null) {
//           throw Exception('Fichier non chargé correctement');
//         }
//         uploadTask = storageRef.putData(
//           pdfFile.bytes!,
//           SettableMetadata(contentType: 'application/pdf'),
//         );
//       } else {
//         // Pour mobile, utiliser le chemin du fichier
//         if (pdfFile.path == null) {
//           throw Exception('Chemin du fichier non disponible');
//         }
//         uploadTask = storageRef.putFile(File(pdfFile.path!));
//       }

//       // Attendre la fin de l'upload
//       final snapshot = await uploadTask.whenComplete(() {});
//       final downloadUrl = await snapshot.ref.getDownloadURL();

//       print('✅ PDF uploadé avec succès: $downloadUrl');
//       return downloadUrl;
//     } catch (e) {
//       print('❌ Erreur upload PDF: $e');
//       rethrow;
//     }
//   }

//   // Ajouter un cours dans Firestore
//   static Future<String> addCourse({
//     required String title,
//     required String description,
//     required String category,
//     required PlatformFile pdfFile,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('Utilisateur non connecté');

//       // 1. Récupérer les infos du formateur
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
//       if (!userDoc.exists) throw Exception('Profil formateur introuvable');

//       final userData = userDoc.data()!;
//       final formateurNom =
//           '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim();

//       // 2. Upload du PDF
//       print('🔄 Upload du PDF en cours...');
//       final pdfUrl = await uploadPdfFile(pdfFile, title);
//       if (pdfUrl == null) throw Exception('Échec de l\'upload du PDF');

//       // 3. Créer le document cours
//       final courseData = createCourseModel(
//         title: title,
//         description: description,
//         category: category,
//         pdfUrl: pdfUrl,
//         fileName: pdfFile.name,
//         fileSize: pdfFile.size,
//         formateurId: user.uid,
//         formateurNom: formateurNom,
//       );

//       // 4. Sauvegarder dans Firestore
//       final docRef = await _firestore.collection('courses').add(courseData);

//       print('✅ Cours ajouté avec l\'ID: ${docRef.id}');
//       return docRef.id;
//     } catch (e) {
//       print('❌ Erreur ajout cours: $e');
//       rethrow;
//     }
//   }

//   // Récupérer tous les cours
//   static Stream<QuerySnapshot> getAllCourses() {
//     return _firestore
//         .collection('courses')
//         .where('isActive', isEqualTo: true)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Récupérer les cours d'un formateur
//   static Stream<QuerySnapshot> getCoursesByFormateur(String formateurId) {
//     return _firestore
//         .collection('courses')
//         .where('formateurId', isEqualTo: formateurId)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Récupérer les cours par catégorie
//   static Stream<QuerySnapshot> getCoursesByCategory(String category) {
//     return _firestore
//         .collection('courses')
//         .where('category', isEqualTo: category)
//         .where('isActive', isEqualTo: true)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Supprimer un cours
//   static Future<void> deleteCourse(String courseId, String pdfUrl) async {
//     try {
//       // 1. Supprimer le fichier PDF du Storage
//       await _storage.refFromURL(pdfUrl).delete();

//       // 2. Supprimer le document Firestore
//       await _firestore.collection('courses').doc(courseId).delete();

//       print('✅ Cours supprimé avec succès');
//     } catch (e) {
//       print('❌ Erreur suppression cours: $e');
//       rethrow;
//     }
//   }

//   // Mettre à jour un cours (sans changer le PDF)
//   static Future<void> updateCourse(
//     String courseId, {
//     String? title,
//     String? description,
//     String? category,
//   }) async {
//     try {
//       final updateData = <String, dynamic>{
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       if (title != null) updateData['title'] = title;
//       if (description != null) updateData['description'] = description;
//       if (category != null) updateData['category'] = category;

//       await _firestore.collection('courses').doc(courseId).update(updateData);

//       print('✅ Cours mis à jour avec succès');
//     } catch (e) {
//       print('❌ Erreur mise à jour cours: $e');
//       rethrow;
//     }
//   }

//   // Incrémenter le nombre de téléchargements
//   static Future<void> incrementDownloadCount(String courseId) async {
//     try {
//       await _firestore.collection('courses').doc(courseId).update({
//         'downloadCount': FieldValue.increment(1),
//       });
//     } catch (e) {
//       print('❌ Erreur incrémentation download: $e');
//     }
//   }

//   // Inscrire un étudiant à un cours
//   static Future<void> enrollStudent(String courseId, String courseTitle) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('Utilisateur non connecté');

//       // Vérifier si déjà inscrit
//       final existingEnrollment = await _firestore
//           .collection('enrollments')
//           .where('studentId', isEqualTo: user.uid)
//           .where('courseId', isEqualTo: courseId)
//           .get();

//       if (existingEnrollment.docs.isNotEmpty) {
//         throw Exception('Vous êtes déjà inscrit à ce cours');
//       }

//       // Créer l'inscription
//       await _firestore.collection('enrollments').add({
//         'studentId': user.uid,
//         'courseId': courseId,
//         'courseTitle': courseTitle,
//         'enrolledAt': FieldValue.serverTimestamp(),
//         'progress': 0,
//         'isCompleted': false,
//         'lastAccessed': FieldValue.serverTimestamp(),
//       });

//       // Incrémenter le compteur d'inscriptions
//       await _firestore.collection('courses').doc(courseId).update({
//         'enrollmentCount': FieldValue.increment(1),
//       });

//       print('✅ Inscription réussie au cours: $courseTitle');
//     } catch (e) {
//       print('❌ Erreur inscription: $e');
//       rethrow;
//     }
//   }

//   // Récupérer les cours d'un étudiant
//   static Stream<QuerySnapshot> getStudentCourses(String studentId) {
//     return _firestore
//         .collection('enrollments')
//         .where('studentId', isEqualTo: studentId)
//         .orderBy('enrolledAt', descending: true)
//         .snapshots();
//   }
// }

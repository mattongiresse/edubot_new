import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'supabase_config.dart';

class SupabaseStorageService {
  static final SupabaseClient _client = SupabaseConfig.client;

  static Future<String?> uploadPdf({
    required String fileName,
    required dynamic fileData,
    required String userId,
    bool isWeb = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Erreur: Aucun utilisateur Firebase connecté');
        throw Exception('Utilisateur non connecté');
      }

      final String filePath =
          'courses/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      print('Uploading to bucket: ${SupabaseConfig.bucketName}');
      print('File path: $filePath');

      String? uploadPath;

      if (isWeb) {
        if (fileData is Uint8List || fileData is List<int>) {
          final bytes = fileData is Uint8List
              ? fileData
              : Uint8List.fromList(fileData as List<int>);
          uploadPath = await _client.storage
              .from(SupabaseConfig.bucketName)
              .uploadBinary(
                filePath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'application/pdf',
                  metadata: {'owner': userId},
                ),
              );
        } else {
          print(
            'Erreur: fileData doit être Uint8List ou List<int> pour le web',
          );
          throw Exception('Données de fichier invalides pour le web');
        }
      } else {
        if (fileData is File) {
          uploadPath = await _client.storage
              .from(SupabaseConfig.bucketName)
              .upload(
                filePath,
                fileData,
                fileOptions: FileOptions(
                  contentType: 'application/pdf',
                  metadata: {'owner': userId},
                ),
              );
        } else {
          print('Erreur: fileData doit être un File pour mobile');
          throw Exception('Données de fichier invalides pour mobile');
        }
      }

      if (uploadPath == null) {
        print('Upload échoué: chemin non retourné');
        throw Exception('Échec de l\'upload: chemin non retourné');
      }

      final String publicUrl = _client.storage
          .from(SupabaseConfig.bucketName)
          .getPublicUrl(filePath);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Erreur upload Supabase: $e');
      throw Exception('Erreur lors de l\'upload: $e');
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Erreur: Aucun utilisateur Firebase connecté');
        throw Exception('Utilisateur non connecté');
      }

      await _client.storage.from(SupabaseConfig.bucketName).remove([filePath]);
      print('Fichier supprimé: $filePath');
      return true;
    } catch (e) {
      print('Erreur suppression Supabase: $e');
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  static String? extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(SupabaseConfig.bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      print('Erreur extraction chemin URL: $e');
      return null;
    }
  }
}

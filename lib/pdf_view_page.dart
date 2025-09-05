import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class PDFViewPage extends StatefulWidget {
  final String pdfPath; // chemin du PDF dans Supabase (ex: "monCours.pdf")

  const PDFViewPage({Key? key, required this.pdfPath}) : super(key: key);

  @override
  State<PDFViewPage> createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage> {
  String? localFilePath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromSupabase();
  }

  Future<void> _loadPdfFromSupabase() async {
    try {
      // 1️⃣ Générer une URL publique ou temporaire depuis Supabase
      final supabase = Supabase.instance.client;

      final response = await supabase.storage
          .from('course-files') // nom du bucket
          .createSignedUrl(widget.pdfPath, 60 * 60); // URL valide 1h

      // 2️⃣ Télécharger le PDF avec http
      final uri = Uri.parse(response);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        // 3️⃣ Sauvegarde temporaire dans le téléphone
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.pdfPath.split('/').last}');
        await file.writeAsBytes(res.bodyBytes, flush: true);

        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      } else {
        throw Exception("Impossible de télécharger le PDF");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Erreur chargement PDF: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de chargement du PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aperçu du cours"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localFilePath != null
          ? PDFView(filePath: localFilePath!)
          : const Center(child: Text("PDF introuvable")),
    );
  }
}

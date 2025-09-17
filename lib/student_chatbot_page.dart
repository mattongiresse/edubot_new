import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Nouvel import pour Gemini

class StudentChatbotPage extends StatefulWidget {
  const StudentChatbotPage({super.key});

  @override
  State<StudentChatbotPage> createState() => _StudentChatbotPageState();
}

class _StudentChatbotPageState extends State<StudentChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Content> _geminiHistory = []; // Historique pour Gemini
  bool _isSending = false;
  bool _showWelcome = true; // Contrôle l'affichage de l'écran de bienvenue
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Charger l'historique de manière asynchrone avec gestion d'erreur après montage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadChatHistory();
      } catch (e) {
        print('Erreur lors de l\'initialisation de l\'historique: $e');
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement de l\'historique: $e'),
              backgroundColor: const Color(
                0xFFE53E3E,
              ), // Rouge IUX pour erreurs
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });

    // Ajoute un prompt système initial pour définir le comportement du bot
    _geminiHistory.add(
      Content(
        role: 'model',
        parts: [
          Part.text(
            'Bonjour ! Je suis EduBot, votre assistant pédagogique. Je peux vous aider avec vos cours, quiz, progression, ou toute question académique. Posez-moi des questions !',
          ),
        ],
      ),
    );

    // Masquer l'écran de bienvenue après 5 secondes ou dès qu'un message est envoyé
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcome = false;
        });
      }
    });
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Utilisateur non connecté, historique non chargé.');
      if (mounted) {
        setState(() {
          _messages.clear(); // Éviter un état incohérent
        });
      }
      return;
    }

    try {
      print('Chargement de l\'historique pour l\'utilisateur: ${user.uid}');
      final chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final List<ChatMessage> loadedMessages = [];
      for (var doc in chatSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue; // Ignorer les documents sans données
        final timestamp = data['timestamp'] as Timestamp?;
        final text = data['text'] as String?;
        final sender = data['sender'] as String?;
        if (text == null || sender == null)
          continue; // Ignorer si texte ou sender manquant
        loadedMessages.add(
          ChatMessage(
            id: doc.id,
            text: text,
            sender: sender,
            timestamp: timestamp ?? FieldValue.serverTimestamp(),
          ),
        );
      }

      loadedMessages.sort(
        (a, b) =>
            (a.timestamp as Timestamp).compareTo(b.timestamp as Timestamp),
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
          _geminiHistory.addAll(
            _messages.map(
              (msg) => Content(
                role: msg.sender == 'user' ? 'user' : 'model',
                parts: [Part.text(msg.text)],
              ),
            ),
          );
          if (_messages.isNotEmpty)
            _showWelcome = false; // Masquer si historique existant
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'historique: $e');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de l\'historique: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour envoyer un message.'),
            backgroundColor: Color(0xFFE53E3E),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
      _showWelcome = false; // Masquer l'écran de bienvenue lors de l'envoi
    });

    try {
      final userMessage = ChatMessage(
        id: '',
        text: _messageController.text.trim(),
        sender: 'user',
        timestamp: FieldValue.serverTimestamp(),
      );

      final userMessageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .add({
            'text': userMessage.text,
            'sender': userMessage.sender,
            'timestamp': userMessage.timestamp,
          });

      setState(() {
        _messages.add(
          ChatMessage(
            id: userMessageDoc.id,
            text: userMessage.text,
            sender: userMessage.sender,
            timestamp: userMessage.timestamp,
          ),
        );
      });

      _messageController.clear();

      _geminiHistory.add(
        Content(role: 'user', parts: [Part.text(userMessage.text)]),
      );

      final aiResponse = await _generateAIResponse();

      final aiMessage = ChatMessage(
        id: '',
        text: aiResponse,
        sender: 'ai',
        timestamp: FieldValue.serverTimestamp(),
      );

      final aiMessageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .add({
            'text': aiMessage.text,
            'sender': aiMessage.sender,
            'timestamp': aiMessage.timestamp,
          });

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: aiMessageDoc.id,
              text: aiMessage.text,
              sender: aiMessage.sender,
              timestamp: aiMessage.timestamp,
            ),
          );
          _isSending = false;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      if (mounted) {
        setState(() => _isSending = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du message: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<String> _generateAIResponse() async {
    try {
      final response = await Gemini.instance.chat(_geminiHistory);
      final text =
          response?.output ??
          'Désolé, je n\'ai pas pu générer une réponse. Réessayez !';

      _geminiHistory.add(Content(role: 'model', parts: [Part.text(text)]));

      return text;
    } catch (e) {
      return 'Erreur avec l\'API Gemini: $e. Vérifiez votre clé API ou connexion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey, // Associer la clé au Scaffold
      backgroundColor: const Color(0xFFF7FAFC), // Gris clair IUX
      appBar: AppBar(
        title: const Text(
          '💬 Chat EduBot',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B46C1), Color(0xFF4C51BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          Expanded(
            child: _showWelcome
                ? _buildWelcomeScreen()
                : _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildMessageItem(_messages[index]),
                        ),
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Étudiant';

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF6B46C1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: _showWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: const Icon(
                Icons.smart_toy,
                size: 80,
                color: Color(0xFF6B46C1),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _showWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Bienvenue, $displayName !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Color(0xFF6B46C1),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              opacity: _showWelcome ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: const Text(
                'Je suis EduBot, votre assistant pédagogique. Commencez à discuter !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6B46C1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 60,
              color: Color(0xFF6B46C1),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue sur EduBot !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Posez-moi des questions sur vos cours, quiz ou autre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    bool isUser = message.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6B46C1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Inter',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF6B46C1),
            child: IconButton(
              icon: _isSending
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final dynamic timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

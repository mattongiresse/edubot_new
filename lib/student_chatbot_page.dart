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
  final List<Content> _geminiHistory =
      []; // Historique pour Gemini (contexte conversationnel)
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    // Ajoute un prompt système initial pour définir le comportement du bot (comme un assistant pédagogique)
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
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
        loadedMessages.add(
          ChatMessage(
            id: doc.id,
            text: data['text'] ?? '',
            sender: data['sender'] ?? 'user',
            timestamp: data['timestamp'] ?? FieldValue.serverTimestamp(),
          ),
        );
      }

      // Reverse to show oldest messages first
      loadedMessages.sort(
        (a, b) =>
            (a.timestamp as Timestamp).compareTo(b.timestamp as Timestamp),
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
        });

        // Reconstruire l'historique Gemini à partir des messages chargés
        _geminiHistory.addAll(
          _messages.map(
            (msg) => Content(
              role: msg.sender == 'user'
                  ? 'user'
                  : 'model', // 'ai' devient 'model' pour Gemini
              parts: [Part.text(msg.text)],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de l\'historique: $e'),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      // Add user message to the list
      final userMessage = ChatMessage(
        id: '',
        text: _messageController.text.trim(),
        sender: 'user',
        timestamp: FieldValue.serverTimestamp(),
      );

      // Save user message to Firestore
      final userMessageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .add({
            'text': userMessage.text,
            'sender': userMessage.sender,
            'timestamp': userMessage.timestamp,
          });

      // Add to UI immediately
      setState(() {
        _messages.add(
          ChatMessage(
            id: userMessageDoc.id,
            text: userMessage.text,
            sender: userMessage.sender,
            timestamp: FieldValue.serverTimestamp(),
          ),
        );
      });

      // Clear input
      _messageController.clear();

      // Ajouter le message utilisateur à l'historique Gemini
      _geminiHistory.add(
        Content(role: 'user', parts: [Part.text(userMessage.text)]),
      );

      // Générer la réponse avec Gemini (en utilisant l'historique pour le contexte)
      final aiResponse = await _generateAIResponse();

      final aiMessage = ChatMessage(
        id: '',
        text: aiResponse,
        sender: 'ai',
        timestamp: FieldValue.serverTimestamp(),
      );

      // Save AI message to Firestore
      final aiMessageDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(user.uid)
          .collection('messages')
          .add({
            'text': aiMessage.text,
            'sender': aiMessage.sender,
            'timestamp': aiMessage.timestamp,
          });

      // Add to UI
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: aiMessageDoc.id,
              text: aiMessage.text,
              sender: aiMessage.sender,
              timestamp: FieldValue.serverTimestamp(),
            ),
          );
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
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

      // Ajouter la réponse de Gemini à l'historique pour le contexte futur
      _geminiHistory.add(Content(role: 'model', parts: [Part.text(text)]));

      return text;
    } catch (e) {
      return 'Erreur avec l\'API Gemini: $e. Vérifiez votre clé API ou connexion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('💬 Chat EduBot'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
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
              color: Colors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 60,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue sur EduBot !',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Posez-moi des questions sur vos cours, quiz ou autre',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
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
          color: isUser ? Colors.deepPurple : Colors.white,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
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

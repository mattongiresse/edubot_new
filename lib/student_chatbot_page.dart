import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentChatbotPage extends StatefulWidget {
  const StudentChatbotPage({super.key});

  @override
  State<StudentChatbotPage> createState() => _StudentChatbotPageState();
}

class _StudentChatbotPageState extends State<StudentChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
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

      // Simulate AI response (in a real app, this would come from an API)
      await Future.delayed(const Duration(seconds: 1));

      // Generate a more helpful AI response based on the user's message
      final aiResponse = _generateAIResponse(userMessage.text);

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

  String _generateAIResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Simple keyword-based responses
    if (lowerMessage.contains('bonjour') ||
        lowerMessage.contains('salut') ||
        lowerMessage.contains('hello')) {
      return 'Bonjour ! Je suis EduBot, votre assistant pédagogique. Comment puis-je vous aider aujourd\'hui ?';
    }

    if (lowerMessage.contains('cours') ||
        lowerMessage.contains('matière') ||
        lowerMessage.contains('sujet')) {
      return 'Pour accéder à vos cours, allez dans la section "Mes Cours" de l\'application. Vous y trouverez tous les cours auxquels vous êtes inscrit. '
          'Si vous avez des questions spécifiques sur un cours, n\'hésitez pas à me demander !';
    }

    if (lowerMessage.contains('quiz') ||
        lowerMessage.contains('examen') ||
        lowerMessage.contains('test')) {
      return 'Vous pouvez accéder aux quiz dans la section "Quiz" de l\'application. Les quiz vous permettent de tester vos connaissances '
          'et de vous entraîner. Si vous voulez des conseils pour réussir un quiz, je peux vous aider !';
    }

    if (lowerMessage.contains('aide') ||
        lowerMessage.contains('help') ||
        lowerMessage.contains('assistance')) {
      return 'Je suis là pour vous aider ! Vous pouvez me poser des questions sur vos cours, vos quiz, ou demander de l\'aide sur un sujet spécifique. '
          'Qu\'aimeriez-vous savoir ?';
    }

    if (lowerMessage.contains('progression') ||
        lowerMessage.contains('statistique') ||
        lowerMessage.contains('score')) {
      return 'Pour voir votre progression, consultez la section "Statistiques" dans l\'application. Vous y trouverez des informations détaillées '
          'sur vos performances, votre progression dans les cours, et vos résultats aux quiz.';
    }

    // Default response
    return 'Merci pour votre message. Je suis EduBot, votre assistant pédagogique. '
        'Je peux vous aider avec vos cours, quiz, et autres questions académiques. '
        'Pouvez-vous me donner plus de détails sur ce dont vous avez besoin ?';
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

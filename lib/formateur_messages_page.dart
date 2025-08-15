import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormateurMessagesPage extends StatefulWidget {
  const FormateurMessagesPage({super.key});

  @override
  State<FormateurMessagesPage> createState() => _FormateurMessagesPageState();
}

class _FormateurMessagesPageState extends State<FormateurMessagesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  String _selectedCourse = '';
  List<String> _myCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('formateurId', isEqualTo: user.uid)
        .get();

    setState(() {
      _myCourses = coursesSnapshot.docs
          .map((doc) => doc.data()['title'] as String)
          .toList();
      if (_myCourses.isNotEmpty) {
        _selectedCourse = _myCourses.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages & Communication'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.message), text: 'Messages'),
            Tab(icon: Icon(Icons.campaign), text: 'Annonces'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessagesTab(),
          _buildAnnouncementsTab(),
          _buildNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        // Filtre par cours
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedCourse.isEmpty ? null : _selectedCourse,
            decoration: const InputDecoration(
              labelText: 'Filtrer par cours',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: _myCourses
                .map(
                  (course) =>
                      DropdownMenuItem(value: course, child: Text(course)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedCourse = val ?? ''),
          ),
        ),

        // Liste des conversations
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getConversationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune conversation',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        'Les étudiants peuvent vous contacter',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final conversations = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final data = conversation.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              (data['studentName'] ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (data['hasUnread'] == true)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        data['studentName'] ?? 'Étudiant inconnu',
                        style: TextStyle(
                          fontWeight: data['hasUnread'] == true
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cours: ${data['courseTitle'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['lastMessage'] ?? 'Aucun message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: data['lastMessage'] == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(data['lastMessageTime']),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (data['unreadCount'] != null &&
                              data['unreadCount'] > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${data['unreadCount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _openChatScreen(
                        conversation.id,
                        data['studentName'] ?? 'Étudiant',
                        data['studentId'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    return Column(
      children: [
        // Formulaire d'annonce
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'Nouvelle Annonce',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCourse.isEmpty ? null : _selectedCourse,
                  decoration: const InputDecoration(
                    labelText: 'Cours concerné',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous mes cours'),
                    ),
                    ..._myCourses.map(
                      (course) =>
                          DropdownMenuItem(value: course, child: Text(course)),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedCourse = val ?? ''),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _announcementController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message d\'annonce',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                    hintText: 'Rédigez votre annonce pour les étudiants...',
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _sendAnnouncement,
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer Annonce'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _scheduleAnnouncement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.schedule),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Liste des annonces envoyées
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getAnnouncementsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune annonce envoyée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final announcements = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  final data = announcement.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getAnnouncementColor(data['type']),
                        child: Icon(
                          _getAnnouncementIcon(data['type']),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        data['courseTitle'] ?? 'Tous les cours',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['message'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${data['viewCount'] ?? 0} vues',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(data['sentAt']),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility),
                                SizedBox(width: 8),
                                Text('Voir détails'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'resend',
                            child: Row(
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text('Renvoyer'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) => _handleAnnouncementAction(
                          value.toString(),
                          announcement.id,
                          data,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return Column(
      children: [
        // Paramètres de notification
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      'Paramètres de Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Nouveaux messages étudiants'),
                  subtitle: const Text(
                    'Recevoir une notification pour chaque nouveau message',
                  ),
                  value: true,
                  onChanged: (value) {},
                  activeColor: Colors.deepPurple,
                ),

                SwitchListTile(
                  title: const Text('Nouvelles inscriptions'),
                  subtitle: const Text(
                    'Notification quand un étudiant s\'inscrit à vos cours',
                  ),
                  value: true,
                  onChanged: (value) {},
                  activeColor: Colors.deepPurple,
                ),

                SwitchListTile(
                  title: const Text('Quiz terminés'),
                  subtitle: const Text(
                    'Notification quand un étudiant termine un quiz',
                  ),
                  value: false,
                  onChanged: (value) {},
                  activeColor: Colors.deepPurple,
                ),

                SwitchListTile(
                  title: const Text('Rappels hebdomadaires'),
                  subtitle: const Text('Résumé hebdomadaire de l\'activité'),
                  value: true,
                  onChanged: (value) {},
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ),

        // Historique des notifications
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final data = notification.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: data['isRead'] == true
                        ? Colors.white
                        : Colors.blue.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(data['type']),
                        child: Icon(
                          _getNotificationIcon(data['type']),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        data['title'] ?? 'Notification',
                        style: TextStyle(
                          fontWeight: data['isRead'] == true
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['message'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(data['createdAt']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: data['isRead'] != true
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => _markNotificationAsRead(notification.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openChatScreen(
    String conversationId,
    String studentName,
    String studentId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          studentName: studentName,
          studentId: studentId,
        ),
      ),
    );
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un message')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('announcements').add({
        'message': _announcementController.text.trim(),
        'courseTitle': _selectedCourse == 'all'
            ? 'Tous les cours'
            : _selectedCourse,
        'formateurId': user.uid,
        'formateurName': user.displayName ?? 'Formateur',
        'sentAt': FieldValue.serverTimestamp(),
        'type': 'announcement',
        'viewCount': 0,
        'isActive': true,
      });

      _announcementController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce envoyée avec succès ! 📢'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _scheduleAnnouncement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programmer une annonce'),
        content: const Text('Fonctionnalité de programmation à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAnnouncementAction(
    String action,
    String announcementId,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case 'view':
        _showAnnouncementDetails(data);
        break;
      case 'resend':
        _resendAnnouncement(data);
        break;
      case 'delete':
        _deleteAnnouncement(announcementId);
        break;
    }
  }

  void _showAnnouncementDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['courseTitle'] ?? 'Annonce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(data['message'] ?? ''),
            SizedBox(height: 16),
            Text(
              'Statistiques:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Vues: ${data['viewCount'] ?? 0}'),
            Text('Envoyé le: ${_formatDate(data['sentAt'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _resendAnnouncement(Map<String, dynamic> data) {
    _announcementController.text = data['message'] ?? '';
    _selectedCourse = data['courseTitle'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message chargé pour renvoyer')),
    );
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette annonce ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcementId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Stream<QuerySnapshot> _getConversationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('conversations')
        .where('formateurId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getAnnouncementsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('announcements')
        .where('formateurId', isEqualTo: user.uid)
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('userType', isEqualTo: 'formateur')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color _getAnnouncementColor(String? type) {
    switch (type) {
      case 'urgent':
        return Colors.red;
      case 'info':
        return Colors.blue;
      case 'reminder':
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getAnnouncementIcon(String? type) {
    switch (type) {
      case 'urgent':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'reminder':
        return Icons.schedule;
      default:
        return Icons.campaign;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'enrollment':
        return Colors.green;
      case 'quiz':
        return Colors.orange;
      case 'system':
        return Colors.grey;
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'enrollment':
        return Icons.person_add;
      case 'quiz':
        return Icons.quiz;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return '${diff.inDays}j';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}min';
      } else {
        return 'maintenant';
      }
    }
    return '';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _announcementController.dispose();
    super.dispose();
  }
}

// Écran de chat individuel
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String studentName;
  final String studentId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat avec ${widget.studentName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final data = message.data() as Map<String, dynamic>;
                    final isFromFormateur =
                        data['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;

                    return Align(
                      alignment: isFromFormateur
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isFromFormateur
                              ? Colors.deepPurple
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                color: isFromFormateur
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatMessageTime(data['sentAt']),
                              style: TextStyle(
                                fontSize: 10,
                                color: isFromFormateur
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
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
                    decoration: const InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.deepPurple,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final message = _messageController.text.trim();

      // Ajouter le message à la conversation
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
            'message': message,
            'senderId': user.uid,
            'senderType': 'formateur',
            'sentAt': FieldValue.serverTimestamp(),
          });

      // Mettre à jour la conversation
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
            'lastMessage': message,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'hasUnread': true,
          });

      _messageController.clear();

      // Scroll vers le bas
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

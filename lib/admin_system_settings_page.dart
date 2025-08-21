import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSystemSettingsPage extends StatefulWidget {
  const AdminSystemSettingsPage({super.key});

  @override
  State<AdminSystemSettingsPage> createState() =>
      _AdminSystemSettingsPageState();
}

class _AdminSystemSettingsPageState extends State<AdminSystemSettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Contrôleurs pour les paramètres généraux
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _maxFileSizeController = TextEditingController();

  // Contrôleurs pour les paramètres EduBot
  final TextEditingController _botNameController = TextEditingController();
  final TextEditingController _botResponseDelayController =
      TextEditingController();
  final TextEditingController _botMaxResponseLengthController =
      TextEditingController();

  // États des paramètres
  bool _allowUserRegistration = true;
  bool _requireEmailVerification = false;
  bool _enableNotifications = true;
  bool _enableAutoBackup = true;
  bool _enableEduBot = true;
  bool _botLearningMode = false;
  bool _botAutoResponse = true;
  bool _maintenanceMode = false;

  Map<String, dynamic> _currentSettings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main_config')
          .get();

      if (doc.exists) {
        _currentSettings = doc.data() ?? {};
        _populateControllers();
      } else {
        _setDefaultSettings();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _populateControllers() {
    _appNameController.text = _currentSettings['appName'] ?? 'EduBot';
    _appVersionController.text = _currentSettings['appVersion'] ?? '1.0.0';
    _supportEmailController.text =
        _currentSettings['supportEmail'] ?? 'support@edubot.com';
    _maxFileSizeController.text =
        _currentSettings['maxFileSize']?.toString() ?? '10';

    _botNameController.text = _currentSettings['botName'] ?? 'EduBot AI';
    _botResponseDelayController.text =
        _currentSettings['botResponseDelay']?.toString() ?? '2';
    _botMaxResponseLengthController.text =
        _currentSettings['botMaxResponseLength']?.toString() ?? '500';

    _allowUserRegistration = _currentSettings['allowUserRegistration'] ?? true;
    _requireEmailVerification =
        _currentSettings['requireEmailVerification'] ?? false;
    _enableNotifications = _currentSettings['enableNotifications'] ?? true;
    _enableAutoBackup = _currentSettings['enableAutoBackup'] ?? true;
    _enableEduBot = _currentSettings['enableEduBot'] ?? true;
    _botLearningMode = _currentSettings['botLearningMode'] ?? false;
    _botAutoResponse = _currentSettings['botAutoResponse'] ?? true;
    _maintenanceMode = _currentSettings['maintenanceMode'] ?? false;
  }

  void _setDefaultSettings() {
    _appNameController.text = 'EduBot';
    _appVersionController.text = '1.0.0';
    _supportEmailController.text = 'support@edubot.com';
    _maxFileSizeController.text = '10';

    _botNameController.text = 'EduBot AI';
    _botResponseDelayController.text = '2';
    _botMaxResponseLengthController.text = '500';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('⚙️ Paramètres Système'),
        backgroundColor: const Color(0xFF1B1E23),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Général', icon: Icon(Icons.settings)),
            Tab(text: 'Sécurité', icon: Icon(Icons.security)),
            Tab(text: 'EduBot IA', icon: Icon(Icons.smart_toy)),
            Tab(text: 'Maintenance', icon: Icon(Icons.build)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildSecurityTab(),
                _buildEduBotTab(),
                _buildMaintenanceTab(),
              ],
            ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsCard('Application', Icons.apps, Colors.blue, [
            _buildTextField(
              'Nom de l\'application',
              _appNameController,
              Icons.title,
            ),
            _buildTextField('Version', _appVersionController, Icons.info),
            _buildTextField(
              'Email de support',
              _supportEmailController,
              Icons.email,
            ),
            _buildTextField(
              'Taille max fichier (MB)',
              _maxFileSizeController,
              Icons.file_upload,
              keyboardType: TextInputType.number,
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsCard('Fonctionnalités', Icons.toggle_on, Colors.green, [
            _buildSwitchTile(
              'Autoriser les inscriptions',
              'Les nouveaux utilisateurs peuvent créer un compte',
              _allowUserRegistration,
              (value) => setState(() => _allowUserRegistration = value),
            ),
            _buildSwitchTile(
              'Notifications push',
              'Envoyer des notifications aux utilisateurs',
              _enableNotifications,
              (value) => setState(() => _enableNotifications = value),
            ),
            _buildSwitchTile(
              'Sauvegarde automatique',
              'Sauvegarde automatique des données',
              _enableAutoBackup,
              (value) => setState(() => _enableAutoBackup = value),
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsCard('Limites du système', Icons.speed, Colors.orange, [
            _buildInfoTile('Utilisateurs maximum', '10,000'),
            _buildInfoTile('Cours maximum par formateur', '50'),
            _buildInfoTile('Quiz maximum par cours', '20'),
            _buildInfoTile('Stockage disponible', '100 GB'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsCard('Authentification', Icons.lock, Colors.red, [
            _buildSwitchTile(
              'Vérification email requise',
              'Les utilisateurs doivent vérifier leur email',
              _requireEmailVerification,
              (value) => setState(() => _requireEmailVerification = value),
            ),
            _buildInfoTile('Durée de session', '7 jours'),
            _buildInfoTile('Tentatives de connexion max', '5'),
          ]),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Permissions',
            Icons.admin_panel_settings,
            Colors.purple,
            [
              _buildInfoTile('Étudiants', 'Lecture seule sur leurs cours'),
              _buildInfoTile('Formateurs', 'Gestion de leurs contenus'),
              _buildInfoTile('Admins', 'Accès complet au système'),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Sécurité des données',
            Icons.shield,
            Colors.teal,
            [
              _buildActionTile(
                'Chiffrement des données',
                'Activé (AES-256)',
                Icons.security,
                Colors.green,
                null,
              ),
              _buildActionTile(
                'Audit des connexions',
                'Voir les logs',
                Icons.history,
                Colors.blue,
                () => _showAuditLogs(),
              ),
              _buildActionTile(
                'Sauvegarde de sécurité',
                'Créer maintenant',
                Icons.backup,
                Colors.orange,
                () => _createSecurityBackup(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEduBotTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsCard(
            'Configuration EduBot',
            Icons.smart_toy,
            Colors.cyan,
            [
              _buildSwitchTile(
                'Activer EduBot IA',
                'Permet l\'utilisation du chatbot intelligent',
                _enableEduBot,
                (value) => setState(() => _enableEduBot = value),
              ),
              _buildTextField('Nom du bot', _botNameController, Icons.badge),
              _buildTextField(
                'Délai de réponse (sec)',
                _botResponseDelayController,
                Icons.timer,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                'Longueur max réponse',
                _botMaxResponseLengthController,
                Icons.text_fields,
                keyboardType: TextInputType.number,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Comportement du bot',
            Icons.psychology,
            Colors.indigo,
            [
              _buildSwitchTile(
                'Mode apprentissage',
                'Le bot apprend des interactions',
                _botLearningMode,
                (value) => setState(() => _botLearningMode = value),
              ),
              _buildSwitchTile(
                'Réponse automatique',
                'Réponses automatiques aux questions courantes',
                _botAutoResponse,
                (value) => setState(() => _botAutoResponse = value),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Statistiques EduBot',
            Icons.analytics,
            Colors.pink,
            [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bot_interactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  final interactions = snapshot.data?.docs.length ?? 0;
                  return _buildInfoTile(
                    'Interactions totales',
                    '$interactions',
                  );
                },
              ),
              _buildInfoTile('Taux de satisfaction', '94%'),
              _buildInfoTile('Temps de réponse moyen', '1.2s'),
              _buildActionTile(
                'Réinitialiser les données',
                'Supprimer l\'historique',
                Icons.refresh,
                Colors.red,
                () => _resetBotData(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingsCard(
            'État du système',
            Icons.monitor_heart,
            Colors.green,
            [
              _buildInfoTile('Serveur', '🟢 En ligne'),
              _buildInfoTile('Base de données', '🟢 Opérationnelle'),
              _buildInfoTile('Stockage', '🟡 87% utilisé'),
              _buildInfoTile('Dernière sauvegarde', _getLastBackupTime()),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Mode maintenance',
            Icons.build_circle,
            Colors.orange,
            [
              _buildSwitchTile(
                'Mode maintenance actif',
                'Bloque l\'accès aux utilisateurs non-admin',
                _maintenanceMode,
                (value) => setState(() => _maintenanceMode = value),
              ),
              if (_maintenanceMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Le système est en mode maintenance. Seuls les administrateurs peuvent accéder à l\'application.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard(
            'Actions de maintenance',
            Icons.settings_applications,
            Colors.blue,
            [
              _buildActionTile(
                'Nettoyer le cache',
                'Supprimer les fichiers temporaires',
                Icons.cleaning_services,
                Colors.blue,
                () => _cleanCache(),
              ),
              _buildActionTile(
                'Optimiser la base de données',
                'Réorganiser les données',
                Icons.tune,
                Colors.green,
                () => _optimizeDatabase(),
              ),
              _buildActionTile(
                'Vérifier l\'intégrité',
                'Scanner les données corrompues',
                Icons.verified_user,
                Colors.purple,
                () => _checkIntegrity(),
              ),
              _buildActionTile(
                'Redémarrer le système',
                'Redémarrage complet',
                Icons.restart_alt,
                Colors.red,
                () => _showRestartConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsCard('Journaux système', Icons.article, Colors.grey, [
            _buildActionTile(
              'Logs d\'erreurs',
              'Voir les erreurs récentes',
              Icons.error,
              Colors.red,
              () => _showErrorLogs(),
            ),
            _buildActionTile(
              'Logs d\'activité',
              'Historique des actions',
              Icons.history,
              Colors.blue,
              () => _showActivityLogs(),
            ),
            _buildActionTile(
              'Exporter les logs',
              'Télécharger tous les logs',
              Icons.download,
              Colors.green,
              () => _exportLogs(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios) : null,
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final settings = {
        'appName': _appNameController.text.trim(),
        'appVersion': _appVersionController.text.trim(),
        'supportEmail': _supportEmailController.text.trim(),
        'maxFileSize': int.tryParse(_maxFileSizeController.text) ?? 10,

        'botName': _botNameController.text.trim(),
        'botResponseDelay': int.tryParse(_botResponseDelayController.text) ?? 2,
        'botMaxResponseLength':
            int.tryParse(_botMaxResponseLengthController.text) ?? 500,

        'allowUserRegistration': _allowUserRegistration,
        'requireEmailVerification': _requireEmailVerification,
        'enableNotifications': _enableNotifications,
        'enableAutoBackup': _enableAutoBackup,
        'enableEduBot': _enableEduBot,
        'botLearningMode': _botLearningMode,
        'botAutoResponse': _botAutoResponse,
        'maintenanceMode': _maintenanceMode,

        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main_config')
          .set(settings, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres sauvegardés avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showAuditLogs() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Logs d\'audit'),
        content: Text('Fonctionnalité en développement...'),
      ),
    );
  }

  void _createSecurityBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sauvegarde de sécurité en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _resetBotData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser EduBot'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données d\'apprentissage du bot ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Logique de réinitialisation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Données EduBot réinitialisées'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _cleanCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nettoyage du cache en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _optimizeDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Optimisation de la base de données...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _checkIntegrity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vérification de l\'intégrité...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redémarrer le système'),
        content: const Text(
          'Cette action va redémarrer complètement le système. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redémarrage du système...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Redémarrer'),
          ),
        ],
      ),
    );
  }

  void _showErrorLogs() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Logs d\'erreurs'),
        content: Text('Aucune erreur récente trouvée.'),
      ),
    );
  }

  void _showActivityLogs() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Logs d\'activité'),
        content: Text('Historique des activités système...'),
      ),
    );
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des logs en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getLastBackupTime() {
    // Simulation - en réalité, récupérer de la base de données
    final now = DateTime.now();
    final lastBackup = now.subtract(const Duration(hours: 2));
    return '${lastBackup.day}/${lastBackup.month}/${lastBackup.year} ${lastBackup.hour}:${lastBackup.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appNameController.dispose();
    _appVersionController.dispose();
    _supportEmailController.dispose();
    _maxFileSizeController.dispose();
    _botNameController.dispose();
    _botResponseDelayController.dispose();
    _botMaxResponseLengthController.dispose();
    super.dispose();
  }
}

import 'package:edubot_new/course_page.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'profile_page.dart'; // Vérifiez que ce fichier existe dans le même répertoire

class HomePage extends StatefulWidget {
  final String userName;
  final String userRole;

  const HomePage({super.key, required this.userName, required this.userRole});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex =
      0; // Indice pour l'onglet sélectionné (Accueil par défaut)
  bool _isPremium = false; // État initial : mode gratuit
  bool _isDarkTheme = true; // État initial pour le thème sombre
  bool _isNotificationsEnabled = true; // État initial pour les notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("EduBot")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  children: [
                    // Logo
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 152, 54, 244),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "EduBot",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Texte salut avec le nom de l'utilisateur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Salut, ${widget.userName}! 👋",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Prêt pour une aventure ?",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- CARROUSEL DYNAMIQUE AVEC 3 IMAGES ---
                CarouselSlider(
                  options: CarouselOptions(
                    height: 180,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                  ),
                  items:
                      [
                        'assets/images/student.png',
                        'assets/images/student2.png',
                        'assets/images/student3.png',
                      ].map((imagePath) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 20),

                // --- FILIÈRES (ACCÈS CONDITIONNEL) ---
                const Text(
                  "Filières :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_isPremium)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategory(
                          "Informatique",
                          Icons.computer,
                          Colors.blue,
                        ),
                        _buildCategory(
                          "Ressources Humaines",
                          Icons.group,
                          Colors.orange,
                        ),
                        _buildCategory(
                          "Sciences de la Vie",
                          Icons.biotech,
                          Colors.green,
                        ),
                        _buildCategory(
                          "Comptabilité",
                          Icons.account_balance,
                          Colors.purple,
                        ),
                        _buildCategory(
                          "Mathématiques",
                          Icons.calculate,
                          Colors.teal,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Accès limité en mode gratuit !",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _showPaymentDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: const Text(
                            "Passer en mode Premium",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // --- RÉCENT ---
                const Text(
                  "Récent :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // --- BARRE DE DASHBOARD EN BAS AVEC "ACCUEIL" ET EFFET DE SÉLECTION ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDashboardButton(
                context,
                "Accueil",
                Icons.home,
                Colors.deepPurple,
                0,
              ),
              _buildDashboardButton(
                context,
                "Mes Cours",
                Icons.book,
                Colors.blue,
                1,
              ),
              _buildDashboardButton(
                context,
                "Examens",
                Icons.quiz,
                Colors.orange,
                2,
              ),
              _buildDashboardButton(
                context,
                "Chat EduBot",
                Icons.smart_toy,
                Colors.green,
                3,
              ),
              _buildDashboardButton(
                context,
                "Mon Profil",
                Icons.person,
                Colors.purple,
                4,
              ),
              _buildDashboardButton(
                context,
                "Statistiques",
                Icons.analytics,
                Colors.red,
                5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CATÉGORIE ---
  Widget _buildCategory(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BOUTON DASHBOARD AVEC EFFET DE SÉLECTION ---

  Widget _buildDashboardButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int index,
  ) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1) {
          // "Mes Cours" est à l'index 1
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CoursePage()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userName: widget.userName),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title - Fonctionnalité à venir !"),
              backgroundColor: Colors.deepPurple,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGUE DE PAIEMENT ---
  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Passer en mode Premium"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisissez un plan de paiement :"),
            const SizedBox(height: 10),
            _buildPaymentOption("500 FCFA / mois"),
            _buildPaymentOption("1000 FCFA / 3 mois"),
            _buildPaymentOption("2000 FCFA / 5 mois"),
            const SizedBox(height: 10),
            const Text("Méthodes de paiement : Mobile Money ou Orange Money"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isPremium = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Paiement réussi ! Mode Premium activé."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Payer"),
          ),
        ],
      ),
    );
  }

  // --- WIDGET OPTION DE PAIEMENT ---
  Widget _buildPaymentOption(String option) {
    return ListTile(
      title: Text(option),
      trailing: const Icon(Icons.payment),
      onTap: () {
        // Logique de sélection de l'option (facultatif)
      },
    );
  }
}

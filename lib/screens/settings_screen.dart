import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Fond gris clair comme Chrome
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 70,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              _buildAccountSection(),
              const SizedBox(height: 20),
              _buildSectionTitle('De base'),
              _buildSettingsGroup([
                _buildSettingsItem(Icons.search, 'Moteur de recherche', 'Google'),
                _buildSettingsItem(Icons.vpn_key_outlined, 'Mots de passe', 'Enregistrer les mots de passe'),
                _buildSettingsItem(Icons.payment, 'Modes de paiement', 'Gérer les cartes'),
                _buildSettingsItem(Icons.location_on_outlined, 'Adresses et autres', 'Remplissage automatique'),
              ]),
              const SizedBox(height: 20),
              _buildSectionTitle('Avancé'),
              _buildSettingsGroup([
                _buildSettingsItem(Icons.security, 'Confidentialité et sécurité', 'Effacer les données de navigation'),
                _buildSettingsItem(Icons.notifications_none, 'Notifications', 'Demander avant d\'envoyer'),
                _buildSettingsItem(Icons.palette_outlined, 'Thème', 'Clair'),
                _buildSettingsItem(Icons.accessibility_new, 'Accessibilité', 'Taille du texte, Zoom'),
                _buildSettingsItem(Icons.language, 'Langues', 'Français (France)'),
              ]),
               const SizedBox(height: 20),
              _buildSectionTitle('À propos'),
              _buildSettingsGroup([
                _buildSettingsItem(
                  Icons.info_outline, 
                  'À propos de DjimSearch',
                  'Version 1.0.0',
                  onTap: () => Navigator.push(context, _slideTransition(const AboutScreen())),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
        title: const Text('Activer la synchronisation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: const Text('Sauvegardez vos favoris, mots de passe et plus encore', style: TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, _slideTransition(const LoginScreen()));
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, bottom: 10),
      child: Text(
        title,
        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[700], size: 24),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$title : Option à venir'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ));
          },
        ),
        // Ajoute un séparateur sauf pour le dernier item (simplifié ici par un Divider visuel)
        Padding(
          padding: const EdgeInsets.only(left: 55, right: 20),
          child: Divider(height: 1, color: Colors.grey[100]),
        ),
      ],
    );
  }
}

// Réutilisation du bouton retour personnalisé pour la cohérence
class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[800], size: 24),
        onPressed: onPressed,
        tooltip: 'Retour',
      ),
    );
  }
}

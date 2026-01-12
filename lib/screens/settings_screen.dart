import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'about_screen.dart';
import '../db_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final DBService _dbService = DBService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  // Nouvelles animations échelonnées pour les blocs
  late Animation<Offset> _block1Slide;
  late Animation<Offset> _block2Slide;
  late Animation<Offset> _block3Slide;


  Map<String, dynamic>? _currentUser;
  String _searchEngine = 'Google';
  String _themeMode = 'Clair';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Durée augmentée
      vsync: this,
    );

    // Animation du bloc 1 (Compte) - 0% à 40%
    _block1Slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
    // Animation du bloc 2 (De base) - 20% à 60%
    _block2Slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );
    // Animation du bloc 3 (Avancé) et bloc 4 (Informations) - 40% à 100%
    _block3Slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );
    
    // Une simple animation de fade globale
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _dbService.getSessionUser();
    final engine = await _dbService.getSetting('search_engine', 'Google');
    final theme = await _dbService.getSetting('theme', 'Clair');
    
    if (mounted) {
      setState(() {
        _currentUser = user;
        _searchEngine = engine;
        _themeMode = theme;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSelectionDialog(String title, List<String> options, String currentValue, Function(String) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => RadioListTile<String>(
            title: Text(opt),
            value: opt,
            groupValue: currentValue,
            onChanged: (val) {
              if (val != null) {
                onSelected(val);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer les données ?'),
        content: const Text('Ceci supprimera définitivement votre historique de navigation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await _dbService.clearHistory();
              Navigator.pop(context, true);
            }, 
            child: const Text('Effacer', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historique effacé.')));
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 70,
        leading: Center(
          child: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            SlideTransition(
              position: _block1Slide,
              child: _buildAccountBlock(),
            ),
            const SizedBox(height: 25),
            SlideTransition(
              position: _block2Slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('De base'),
                  _buildSettingsBlock([
                    _buildSettingsItem(Icons.search, 'Moteur de recherche', _searchEngine, onTap: () {
                      _showSelectionDialog('Moteur de recherche', ['Google', 'Bing', 'DuckDuckGo', 'Yahoo'], _searchEngine, (val) {
                        _dbService.updateSetting('search_engine', val);
                        setState(() => _searchEngine = val);
                      });
                    }),
                    _buildSettingsItem(Icons.vpn_key_outlined, 'Mots de passe', 'Gérer vos accès'),
                    _buildSettingsItem(Icons.payment, 'Modes de paiement', 'Cartes enregistrées'),
                    _buildSettingsItem(Icons.location_on_outlined, 'Adresses', 'Remplissage automatique'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SlideTransition(
              position: _block3Slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Avancé'),
                  _buildSettingsBlock([
                    _buildSettingsItem(Icons.security, 'Confidentialité', 'Effacer l\'historique', onTap: _clearData),
                    _buildSettingsItem(Icons.notifications_none, 'Notifications', 'Gérer les alertes'),
                    _buildSettingsItem(Icons.palette_outlined, 'Thème', _themeMode, onTap: () {
                      _showSelectionDialog('Thème', ['Clair', 'Sombre', 'Système'], _themeMode, (val) {
                        _dbService.updateSetting('theme', val);
                        setState(() => _themeMode = val);
                      });
                    }),
                    _buildSettingsItem(Icons.language, 'Langue', 'Français'),
                  ]),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Informations'),
                  _buildSettingsBlock([
                    _buildSettingsItem(
                      Icons.info_outline, 
                      'À propos',
                      'DjimSearch v1.0.0',
                      onTap: () => Navigator.push(context, _slideTransition(const AboutScreen())),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBlock() {
    final colorScheme = Theme.of(context).colorScheme;
    bool loggedIn = _currentUser != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(loggedIn ? Icons.person : Icons.sync, color: colorScheme.onPrimaryContainer, size: 30),
        ),
        title: Text(
          loggedIn ? '${_currentUser!['users_prenom']} ${_currentUser!['users_nom']}' : 'Activer la synchro', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text(loggedIn ? _currentUser!['users_email'] : 'Sauvegardez vos favoris et mots de passe'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          if (!loggedIn) {
            final user = await Navigator.push(context, _slideTransition(const LoginScreen()));
            if (user != null) _loadData();
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsBlock(List<Widget> items) {
    final colorScheme = Theme.of(context).colorScheme;
    List<Widget> childrenWithDividers = [];
    for (int i = 0; i < items.length; i++) {
      childrenWithDividers.add(items[i]);
      if (i < items.length - 1) {
        childrenWithDividers.add(Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(children: childrenWithDividers),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title : Disponible prochainement')));
      },
    );
  }
}

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CustomBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5))
      ),
    );
  }
}
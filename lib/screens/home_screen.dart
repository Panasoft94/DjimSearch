import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'login_screen.dart'; 
import 'about_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'tab_groups_screen.dart'; 
import 'help_screen.dart';
import 'downloads_screen.dart'; // NOUVEAU: Importation de la page des téléchargements
import '../db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
  late final AnimationController _animController;

  // Animation pour le Logo/Titre
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  // Animation pour la Barre de Recherche
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;
  // Animation pour les Actions Rapides et Copyright
  late final Animation<double> _actionsFade;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _appBarFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final DBService _dbService = DBService();

  bool _isFocused = false;
  bool _showWebView = false;
  double _loadingProgress = 0;
  List<String> _suggestions = [];
  bool _canGoBack = false;
  bool _canGoForward = false;

  // Utilisateur connecté
  Map<String, dynamic>? _currentUser;

  // Historique des dernières recherches
  List<Map<String, dynamic>> _recentHistory = [];

  // --- MODIFICATIONS POUR LE GROUPE ACTIF ---
  Map<String, dynamic>? _activeGroup;
  bool _isSearchLoading = false; // Pour savoir quand une sauvegarde est pertinente
  static const String _activeGroupKey = 'active_tab_group_id'; // Clé de persistance
  // --- FIN DES MODIFICATIONS ---

  // Reconnaissance vocale
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  static const String googleSearchUrl = 'https://www.google.com/search?q=';

  @override
  void initState() {
    super.initState();
    _initController();
    _initSpeech();
    _loadSession();
    _loadHistory(); // Charger l'historique
    _loadActiveGroup(); // NOUVEAU: Charger le groupe actif

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Durée plus longue pour l'effet d'échelonnement
    );

    _logoFade = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
    _searchFade = CurvedAnimation(parent: _animController, curve: const Interval(0.25, 0.75, curve: Curves.easeOut));
    _searchSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic)));
    _actionsFade = CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    _animController.forward();

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (!_isFocused) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_focusNode.hasFocus) {
              setState(() {
                _suggestions = [];
              });
            }
          });
        }
      });
    });
  }

  Future<void> _loadActiveGroup() async {
    final activeGroupIdString = await _dbService.getSetting(_activeGroupKey, '0');
    final activeGroupId = int.tryParse(activeGroupIdString) ?? 0;

    if (activeGroupId > 0) {
      final group = await _dbService.getTabGroupById(activeGroupId);
      if (group != null && mounted) {
        setState(() {
          _activeGroup = group;
        });
      } else if (activeGroupId > 0) {
        // Le groupe n'existe plus, on efface la clé
        _dbService.updateSetting(_activeGroupKey, '0');
      }
    }
  }

  Future<void> _setActiveGroup(Map<String, dynamic>? group) async {
    setState(() {
      _activeGroup = group;
    });
    // Sauvegarde l'ID du groupe actif ou '0' si null
    final idToSave = group != null ? group['group_id'].toString() : '0';
    await _dbService.updateSetting(_activeGroupKey, idToSave);
  }

  Future<void> _loadSession() async {
    final user = await _dbService.getSessionUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await _dbService.getRecentHistoryForHome();
    if (mounted) {
      setState(() {
        _recentHistory = history;
      });
    }
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    _appBarFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
            if (progress > 10) _hideGoogleTabs();
          },
          onPageFinished: (String url) async {
            _hideGoogleTabs();

            // MODIFIÉ: Logique de sauvegarde conditionnelle
            if (_isSearchLoading) {
              if (_activeGroup != null) {
                final title = await controller.getTitle();
                await _dbService.addTabToGroup(_activeGroup!['group_id'], url, title: title ?? 'Sans titre');
              }
            }

            final canGoBack = await controller.canGoBack();
            final canGoForward = await controller.canGoForward();
            if (mounted) {
              setState(() {
                _loadingProgress = 0;
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
                _isSearchLoading = false; // Réinitialiser le drapeau
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _showWebView = false;
                _loadingProgress = 0;
                _isSearchLoading = false; // Réinitialiser aussi en cas d'erreur
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pas de connexion"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
              );
            }
          },
        ),
      );
  }

  void _hideGoogleTabs() {
    const String jsCode = """
      (function() {
        if (window.location.hostname.indexOf('google') === -1) return;
        var styleId = 'djimsearch-custom-style';
        function injectStyle() {
          var style = document.createElement('style');
          style.id = styleId;
          style.type = 'text/css';
          document.head.appendChild(style);
          style.innerHTML = `
            header, #header, #searchform, .sfbg, #top_nav, .fbar, .gb_1, 
            div[role="navigation"], nav, footer { display: none !important; }
            #main, #rcnt, #cnt, body { margin-top: 0 !important; top: 0 !important; }
          `;
        }
        
        var style = document.getElementById(styleId);
        if (!style) {
            injectStyle();
        } else {
             // S'assurer que le style est réappliqué au cas où Google le retire
             style.innerHTML = `
                header, #header, #searchform, .sfbg, #top_nav, .fbar, .gb_1, 
                div[role="navigation"], nav, footer { display: none !important; }
                #main, #rcnt, #cnt, body { margin-top: 0 !important; top: 0 !important; }
             `;
        }

        if (!window.djimObserver) {
          window.djimObserver = new MutationObserver(function(mutations) {
             var style = document.getElementById(styleId);
             if (!style) injectStyle();
          });
          window.djimObserver.observe(document.head, { childList: true, subtree: true });
        }
      })();
    """;
    controller.runJavaScript(jsCode);
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(onStatus: (val) {
          if (val == 'done' || val == 'notListening') setState(() => _isListening = false);
        }, onError: (val) => setState(() => _isListening = false));
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _performSearch(val.recognizedWords);
            }
          }));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accès au micro refusé")));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final response = await http.get(Uri.parse('https://suggestqueries.google.com/complete/search?client=chrome&q=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _suggestions = List<String>.from(data[1]));
      }
    } catch (e) {}
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      final searchUrl = '$googleSearchUrl${Uri.encodeComponent(query)}';
      controller.loadRequest(Uri.parse(searchUrl));

      // MODIFIÉ: Ajout conditionnel à l'historique
      if (_activeGroup == null) {
        _dbService.addHistory(query);
        _loadHistory();
      }

      setState(() {
        _showWebView = true;
        _isSearchLoading = true; // Indiquer qu'une recherche démarre
        _suggestions = [];
        _canGoBack = false;
        _canGoForward = false;
      });
      _focusNode.unfocus();
      _appBarFocusNode.unfocus();
    }
  }

  Future<void> _deleteHistoryItem(int id) async {
    await _dbService.deleteHistoryItem(id);
    _loadHistory();
  }

  PopupMenuItem<String> _buildPopupItem(String text, IconData icon, String value, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return PopupMenuItem<String>(value: value, child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 15), Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color))]));
  }

  void _showHelpOptions() {
    // MODIFIÉ: La navigation se fait vers HelpScreen
    Navigator.push(context, _slideTransition(const HelpScreen()));
  }

  void _showNewGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Nouveau Groupe d\'Onglets'),
      content: TextField(controller: groupNameController, decoration: const InputDecoration(hintText: 'Nom du groupe', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
        TextButton(onPressed: () async {
          final name = groupNameController.text.isNotEmpty ? groupNameController.text : 'Groupe sans nom';
          await _dbService.addTabGroup(name);
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Groupe "$name" créé avec succès.')));
        }, child: const Text('CRÉER')),
      ],
    ));
  }

  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(pageBuilder: (_, __, ___) => page, transitionsBuilder: (_, animation, __, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation), child: child));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool canPop = Navigator.of(context).canPop();
    final bool canGoBackInWeb = _showWebView && _canGoBack;
    final bool canGoForwardInWeb = _showWebView && _canGoForward;
    final backButtonEnabled = canGoBackInWeb || canPop;
    final backButtonColor = backButtonEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38);
    final forwardButtonColor = canGoForwardInWeb ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 85,
        elevation: _showWebView ? 1.0 : 0.0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 4),
            _buildNavButton(Icons.arrow_back_rounded, backButtonColor, backButtonEnabled ? () { if (canGoBackInWeb) controller.goBack(); else Navigator.pop(context); } : null, 'Retour'),
            const SizedBox(width: 4),
            _buildNavButton(Icons.arrow_forward_rounded, forwardButtonColor, canGoForwardInWeb ? () => controller.goForward() : null, 'Suivant'),
          ]),
        ),
        title: Padding(padding: const EdgeInsets.only(top: 15.0), child: _buildSearchBar(isSmall: true)),
        actions: [Padding(padding: const EdgeInsets.only(top: 15.0, right: 5), child: _buildMainMenu())],
        // MODIFIÉ: Utilisation d'une méthode pour la bottom bar
        bottom: _buildAppBarBottom(colorScheme),
      ),
      floatingActionButton: _showWebView ? FloatingActionButton(onPressed: () => controller.reload(), backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, elevation: 4, child: const Icon(Icons.refresh)) : null,
      body: SafeArea(
        child: Stack(children: [
          _showWebView ? WebViewWidget(controller: controller) : _buildHomeBody(),
          if (!_showWebView && _suggestions.isNotEmpty && _isFocused) _buildSuggestionsList(colorScheme),
        ]),
      ),
    );
  }

  // NOUVEAU: Méthode pour construire le menu principal
  PopupMenuButton<String> _buildMainMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        switch (value) {
          case 'new_tab': Navigator.push(context, _slideTransition(const HomeScreen())); break;
          case 'new_group': _showNewGroupDialog(); break;
          case 'manage_groups':
            final result = await Navigator.push(context, _slideTransition(const TabGroupsScreen()));
            if (result != null && result is Map<String, dynamic>) {
              _setActiveGroup(result); // UTILISE LA NOUVELLE MÉTHODE
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Groupe "${result['group_name']}" activé.')));
            }
            break;
          // NOUVEAU: Action pour retirer le groupe actif
          case 'clear_group':
            _setActiveGroup(null); // UTILISE LA NOUVELLE MÉTHODE
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Groupe actif retiré.')));
            break;
          case 'history':
            final selectedQuery = await Navigator.push(context, _slideTransition(const HistoryScreen()));
            if (selectedQuery != null && selectedQuery is String) {
              _searchController.text = selectedQuery;
              _performSearch(selectedQuery);
            }
            break;
          case 'downloads': 
            Navigator.push(context, _slideTransition(const DownloadsScreen())); // MODIFIÉ: Navigation vers DownloadsScreen
            break;
          case 'settings': Navigator.push(context, _slideTransition(const SettingsScreen())); break;
          case 'help': _showHelpOptions(); break; // APPEL À LA LOGIQUE MISE À JOUR
          case 'about': Navigator.push(context, _slideTransition(const AboutScreen())); break;
          case 'sync':
             if (_currentUser == null) {
                final user = await Navigator.push(context, _slideTransition(const LoginScreen()));
                if (user != null && user is Map<String, dynamic>) {
                  await _dbService.saveSession(user['users_id']);
                  setState(() => _currentUser = user);
                }
              } else {
                await _dbService.clearSession();
                setState(() => _currentUser = null);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous avez été déconnecté.')));
              }
              break;
          case 'exit': SystemNavigator.pop(); break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('Nouvel onglet', Icons.add_box_outlined, 'new_tab'),
        _buildPopupItem('Nouveau groupe', Icons.create_new_folder_outlined, 'new_group'),
        _buildPopupItem('Mes groupes', Icons.folder_copy_outlined, 'manage_groups'),
        // NOUVEAU: Item conditionnel
        if (_activeGroup != null) _buildPopupItem('Retirer le groupe actif', Icons.layers_clear_outlined, 'clear_group', isDestructive: true),
        const PopupMenuDivider(),
        _buildPopupItem('Historique', Icons.history, 'history'),
        _buildPopupItem('Téléchargements', Icons.download_rounded, 'downloads'),
        const PopupMenuDivider(),
        _buildPopupItem('Paramètres', Icons.settings_outlined, 'settings'),
        _buildPopupItem('Aide', Icons.help_outline, 'help'), // L'ACTION EST DANS _showHelpOptions
        _buildPopupItem('À propos', Icons.info_outline, 'about'),
        _buildPopupItem(_currentUser == null ? 'Connexion / Sync' : 'Se déconnecter', _currentUser == null ? Icons.sync_rounded : Icons.logout_rounded, 'sync', isDestructive: _currentUser != null),
        const PopupMenuDivider(),
        _buildPopupItem('Quitter', Icons.power_settings_new_rounded, 'exit', isDestructive: true),
      ],
    );
  }

  // NOUVEAU: Widget pour la partie inférieure de l'AppBar
  PreferredSize? _buildAppBarBottom(ColorScheme colorScheme) {
    final bool hasProgress = _loadingProgress > 0 && _loadingProgress < 1;
    final bool hasActiveGroup = _activeGroup != null && _showWebView;

    if (!hasProgress && !hasActiveGroup) return null;

    final double preferredHeight = (hasProgress ? 2.0 : 0.0) + (hasActiveGroup ? 32.0 : 0.0);
    
    return PreferredSize(
      preferredSize: Size.fromHeight(preferredHeight),
      child: Column(
        children: [
          if (hasProgress)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 2,
            ),
          if (hasActiveGroup)
            Container(
              height: 32,
              color: colorScheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                Icon(Icons.folder_open_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text("Enregistrement dans : ${_activeGroup!['group_name']}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _setActiveGroup(null), visualDensity: VisualDensity.compact, tooltip: 'Arrêter l\'enregistrement') // UTILISE LA NOUVELLE MÉTHODE
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, Color color, VoidCallback? onPressed, String tooltip) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
      ),
    );
  }

  Widget _buildHomeBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool hideButtons = _suggestions.isNotEmpty && _isFocused;

    return LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: IntrinsicHeight(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(children: [
          const Spacer(flex: 3),
          FadeTransition(opacity: _logoFade, child: SlideTransition(position: _logoSlide, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Padding(padding: const EdgeInsets.only(right: 5.0), child: Image.asset('assets/img/logo.png', height: 100)), Text('Djim', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colorScheme.primary, letterSpacing: -2)), Text('Search', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colorScheme.error, letterSpacing: -2))]))),
          const SizedBox(height: 40),
          FadeTransition(opacity: _searchFade, child: SlideTransition(position: _searchSlide, child: _buildSearchBar(isSmall: false))),
          // NOUVEAU: Affichage du groupe actif sur l'écran d'accueil
          if (_activeGroup != null && !_showWebView) Padding(padding: const EdgeInsets.only(top: 20), child: Chip(label: Text('Groupe actif : ${_activeGroup!['group_name']}'), onDeleted: () => _setActiveGroup(null))), // UTILISE LA NOUVELLE MÉTHODE
          const SizedBox(height: 30),
          FadeTransition(opacity: _actionsFade, child: IgnorePointer(ignoring: hideButtons, child: AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: hideButtons ? 0.0 : 1.0, child: Wrap(spacing: 12, runSpacing: 12, children: _recentHistory.where((item) => item['history_query'] is String && (item['history_query'] as String).isNotEmpty).map((item) {
            final query = item['history_query'] as String;
            final id = item['history_id'] as int;
            return _buildHistoryAction(query, id, colorScheme.primary);
          }).toList())))),
          const Spacer(flex: 4),
          FadeTransition(opacity: _actionsFade, child: Padding(padding: const EdgeInsets.only(bottom: 20), child: Text('Copyright © Panasoft Corporation', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)))),
        ]),
      ))),
    ));
  }

  Widget _buildSearchBar({required bool isSmall}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    FocusNode currentFocusNode = isSmall && !_showWebView ? _appBarFocusNode : _focusNode;

    Widget searchBarContent = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isSmall ? 48 : 55,
        decoration: BoxDecoration(
          color: isSmall ? colorScheme.surface : colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          border: Border.all(color: currentFocusNode.hasFocus ? colorScheme.primary : colorScheme.outline, width: 1.2),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: currentFocusNode,
          onSubmitted: _performSearch,
          onChanged: (value) {
            _fetchSuggestions(value);
            setState(() {});
          },
          style: const TextStyle(fontSize: 15),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Rechercher ou saisir une URL',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, size: 22, color: colorScheme.onSurfaceVariant),
            suffixIcon: IconButton(icon: Icon(_isListening ? Icons.graphic_eq_rounded : Icons.mic, color: _isListening ? colorScheme.error : colorScheme.primary, size: 22), onPressed: _listen),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
    );

    // CORRECTION DE BUG: Seule la barre de recherche principale (isSmall: false) 
    // doit être le CompositedTransformTarget pour éviter les conflits LayerLink.
    if (!isSmall) {
      return CompositedTransformTarget(
        link: _layerLink,
        child: searchBarContent,
      );
    }
    
    return searchBarContent;
  }

  Widget _buildHistoryAction(String label, int id, Color color) {
    return InputChip(
      avatar: Icon(Icons.history, color: color, size: 18),
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label);
      },
      onDeleted: () => _deleteHistoryItem(id),
      deleteIcon: const Icon(Icons.close, size: 18),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    );
  }

  Widget _buildSuggestionsList(ColorScheme colorScheme) {
     return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 0),
      child: Container(
        width: MediaQuery.of(context).size.width - 50,
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: colorScheme.outline),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 5, bottom: 10),
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) => ListTile(
            dense: true,
            leading: Icon(Icons.history, size: 20, color: colorScheme.onSurfaceVariant),
            title: Text(_suggestions[index]),
            onTap: () {
              _searchController.text = _suggestions[index];
              _performSearch(_suggestions[index]);
            },
          ),
        ),
      ),
    );
  }
}

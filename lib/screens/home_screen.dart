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

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Durée plus longue pour l'effet d'échelonnement
    );

    // 1. Logo/Titre (Démarre immédiatement, finit à 50% de la durée)
    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.1), // Petite descente
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // 2. Barre de Recherche (Démarre à 25%, finit à 75%)
    _searchFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _searchSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), // Descente moyenne
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    ));

    // 3. Actions Rapides et Copyright (Démarre à 50%, finit à 100%)
    _actionsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

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
            final canGoBack = await controller.canGoBack();
            final canGoForward = await controller.canGoForward();
            if (mounted) {
              setState(() {
                _loadingProgress = 0;
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _showWebView = false;
                _loadingProgress = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Désolé, il n'y a pas de connexion"),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                ),
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
          var style = document.getElementById(styleId);
          if (!style) {
            style = document.createElement('style');
            style.id = styleId;
            style.type = 'text/css';
            document.head.appendChild(style);
          }
          style.innerHTML = `
            #gb, .gb_1, .gb_2, .gb_ca, .gb_cd, .gb_T, .gb_Od, a[href*="accounts.google.com"],
            header, #header, #searchform, .sfbg, .KxwPGc, #tsf, .DnR6G, 
            #top_nav, .A8SBwf, .fbar, .Nt57O, .F9z5Nd, .Tvx9Oe, .Q7SBjd, .M7pB2,
            #hdtb, #hdtb-msb, .hdtb-mitem, .IUOThf, .t2VTOd, .e9EfHf, .G7G39b,
            .mJX7e, .YmvwI, .s85Vd, .dt25kb, .rveQfe, .MA7Khd, .yg51vc,
            div[role="navigation"], nav,
            footer, .fbar { display: none !important; }
            #main, #rcnt, #cnt, body { margin-top: 0 !important; top: 0 !important; padding-top: 0 !important; }
          `;
        }
        injectStyle();
        if (!window.djimObserver) {
          window.djimObserver = new MutationObserver(function(mutations) {
             var style = document.getElementById(styleId);
             if (!style) injectStyle();
          });
          window.djimObserver.observe(document.head, { childList: true, subtree: true });
        }
      })();
    """
    ;
    controller.runJavaScript(jsCode);
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') setState(() => _isListening = false);
          },
          onError: (val) => setState(() => _isListening = false),
        );
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) => setState(() {
              _searchController.text = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
                _performSearch(val.recognizedWords);
              }
            }),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Accès au micro refusé")),
        );
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
    final url = Uri.parse('https://suggestqueries.google.com/complete/search?client=chrome&q=$query');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final List suggestions = data[1];
        setState(() {
          _suggestions = suggestions.cast<String>();
        });
      }
    } catch (e) {}
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      final searchUrl = '$googleSearchUrl${Uri.encodeComponent(query)}';
      controller.loadRequest(Uri.parse(searchUrl));

      // Enregistrer dans l'historique
      _dbService.addHistory(query);
      _loadHistory(); // Recharger l'historique après une nouvelle recherche

      setState(() {
        _showWebView = true;
        _suggestions = [];
        _canGoBack = false;
        _canGoForward = false;
      });
      _focusNode.unfocus();
      _appBarFocusNode.unfocus();
    }
  }

  PopupMenuItem<String> _buildPopupItem(String text, IconData icon, String value, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 15),
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  void _showHelpOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15, left: 20),
              child: Text('Aide et commentaires', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            _buildHelpItem('Nouveauté', Icons.new_releases_rounded, Colors.purple),
            _buildHelpItem("Centre d'aide", Icons.help_outline_rounded, Colors.blue),
            _buildHelpItem('Signaler un problème', Icons.bug_report_rounded, Colors.orange),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      },
    );
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
        elevation: 1.0, // Ajout d'une légère élévation M3 pour la séparation
        backgroundColor: colorScheme.surface, // Couleur de fond solide et propre
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              _buildNavButton(Icons.arrow_back_rounded, backButtonColor, backButtonEnabled ? () {
                if (canGoBackInWeb) {
                  controller.goBack();
                } else {
                  Navigator.pop(context);
                }
              } : null, 'Retour'),
              const SizedBox(width: 4),
              _buildNavButton(Icons.arrow_forward_rounded, forwardButtonColor, canGoForwardInWeb ? () => controller.goForward() : null, 'Suivant'),
            ],
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: _buildSearchBar(isSmall: true),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0, right: 5),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface, size: 28),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              onSelected: (value) async {
                switch (value) {
                  case 'new_tab':
                    Navigator.push(context, _slideTransition(const HomeScreen()));
                    break;
                  case 'new_group':
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nouveau groupe (À venir)')));
                    break;
                  case 'history':
                    final selectedQuery = await Navigator.push(context, _slideTransition(const HistoryScreen()));
                    if (selectedQuery != null && selectedQuery is String) {
                      _searchController.text = selectedQuery;
                      _performSearch(selectedQuery);
                    }
                    break;
                  case 'downloads':
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargements (À venir)')));
                    break;
                  case 'settings':
                     Navigator.push(context, _slideTransition(const SettingsScreen()));
                    break;
                  case 'help':
                    _showHelpOptions();
                    break;
                  case 'about':
                    Navigator.push(context, _slideTransition(const AboutScreen()));
                    break;
                  case 'sync':
                    if (_currentUser == null) {
                      // Aller à l'écran de connexion et récupérer l'utilisateur
                      final user = await Navigator.push(context, _slideTransition(const LoginScreen()));
                      if (user != null && user is Map<String, dynamic>) {
                        await _dbService.saveSession(user['users_id']);
                        setState(() {
                          _currentUser = user;
                        });
                      }
                    } else {
                      // Se déconnecter
                      await _dbService.clearSession();
                      setState(() {
                        _currentUser = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vous avez été déconnecté.')),
                      );
                    }
                    break;
                  case 'exit':
                    SystemNavigator.pop();
                    break;
                }
              },
              itemBuilder: (context) => [
                _buildPopupItem('Nouvel onglet', Icons.add_box_outlined, 'new_tab'),
                _buildPopupItem('Nouveau groupe', Icons.create_new_folder_outlined, 'new_group'),
                const PopupMenuDivider(),
                _buildPopupItem('Historique', Icons.history, 'history'),
                _buildPopupItem('Téléchargements', Icons.download_rounded, 'downloads'),
                const PopupMenuDivider(),
                _buildPopupItem('Paramètres', Icons.settings_outlined, 'settings'),
                _buildPopupItem('Aide', Icons.help_outline, 'help'),
                _buildPopupItem('À propos', Icons.info_outline, 'about'),
                _buildPopupItem(
                  _currentUser == null ? 'Connexion / Sync' : 'Se déconnecter',
                  _currentUser == null ? Icons.sync_rounded : Icons.logout_rounded,
                  'sync',
                  isDestructive: _currentUser != null,
                ),
                const PopupMenuDivider(),
                _buildPopupItem('Quitter', Icons.power_settings_new_rounded, 'exit', isDestructive: true),
              ],
            ),
          ),
        ],
        bottom: _loadingProgress > 0 && _loadingProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : null,
      ),
      floatingActionButton: _showWebView
          ? FloatingActionButton(
              onPressed: () => controller.reload(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 4,
              child: const Icon(Icons.refresh),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            _showWebView ? WebViewWidget(controller: controller) : _buildHomeBody(),
            if (!_showWebView && _suggestions.isNotEmpty && _isFocused)
              CompositedTransformFollower(
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
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.history, size: 20, color: colorScheme.onSurfaceVariant),
                        title: Text(_suggestions[index]),
                        onTap: () {
                          _searchController.text = _suggestions[index];
                          _performSearch(_suggestions[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
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
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool hideButtons = _suggestions.isNotEmpty && _isFocused;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    const spacer(flex: 3),

                    // animation: logo and title
                    fadetransition(
                      opacity: _logofade,
                      child: slidetransition(
                        position: _logoslide,
                        child: row(
                          mainaxisalignment: mainaxisalignment.center,
                          // remplacement de l'ancien texte par le logo et le nouveau texte
                          children: [
                            // logo
                            padding(
                              padding: const edgeinsets.only(right: 5.0), // marge réduite pour rapprocher le logo du texte
                              child: image.asset(
                                'assets/img/logo.png',
                                height: 100, // augmenté de 60 à 80
                              ),
                            ),
                            // texte "djim search" (utilisant le style m3)
                            text('djim', style: textstyle(fontsize: 36, fontweight: fontweight.bold, color: colorscheme.primary, letterspacing: -2)), // réduit de 54 à 48
                            text('search', style: textstyle(fontsize: 36, fontweight: fontweight.bold, color: colorscheme.error, letterspacing: -2)), // réduit de 54 à 48
                          ],
                        ),
                      ),
                    ),
                    const sizedbox(height: 40),

                    // animation: search bar
                    fadetransition(
                      opacity: _searchfade,
                      child: slidetransition(
                        position: _searchslide,
                        child: _buildsearchbar(issmall: false),
                      ),
                    ),
                    const sizedbox(height: 30),

                    // animation: quick actions (basé sur l'historique)
                    fadetransition(
                      opacity: _actionsfade,
                      child: ignorepointer(
                        ignoring: hidebuttons,
                        child: animatedopacity(
                          duration: const duration(milliseconds: 200),
                          opacity: hidebuttons ? 0.0 : 1.0,
                          child: wrap(
                            spacing: 12,
                            runspacing: 12,
                            children: _recenthistory
                                .where((item) => item['history_query'] is string && (item['history_query'] as string).isnotempty)
                                .map((item) {
                              final query = item['history_query'] as string;
                              return _buildhistoryaction(query, colorscheme.primary);
                            }).tolist(),
                          ),
                        ),
                      ),
                    ),

                    const spacer(flex: 4),

                    // animation: copyright
                    fadetransition(
                      opacity: _actionsfade,
                      child: padding(
                        padding: const edgeinsets.only(bottom: 20),
                        child: text(
                          'copyright © panasoft corporation',
                          style: theme.texttheme.bodysmall?.copywith(color: colorscheme.onsurfacevariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar({required bool isSmall}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    bool showSuggestions = _suggestions.isNotEmpty && _isFocused && !isSmall;

    FocusNode currentFocusNode = isSmall && !_showWebView ? _appBarFocusNode : _focusNode;

    Widget searchBar = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isSmall ? 48 : 55,
      decoration: BoxDecoration(
        color: isSmall ? colorScheme.surface : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.all(Radius.circular(30)),
        border: Border.all(
          color: (isSmall && !_showWebView ? _appBarFocusNode.hasFocus : _isFocused)
              ? colorScheme.primary
              : colorScheme.outline,
          width: 1.2,
        ),
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
        // Centre verticalement le texte, améliorant l'alignement du placeholder.
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Rechercher ou saisir une URL',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 22, color: colorScheme.onSurfaceVariant),
          suffixIcon: IconButton(
            icon: Icon(
              _isListening ? Icons.graphic_eq_rounded : Icons.mic,
              color: _isListening ? colorScheme.error : colorScheme.primary,
              size: 22
            ),
            onPressed: _listen,
          ),
          // J'ai enlevé le contentPadding personnalisé qui causait le décalage.
          contentPadding: const EdgeInsets.symmetric(horizontal: 20), // Padding horizontal seulement
        ),
      ),
    );

    if (!isSmall) {
      return CompositedTransformTarget(
        link: _layerLink,
        child: searchBar,
      );
    }

    return searchBar;
  }

  Widget _buildHistoryAction(String label, Color color) {
    return ActionChip(
      avatar: Icon(Icons.history, color: color, size: 18),
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label);
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

import 'dart:async';
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
import 'downloads_screen.dart';
import '../db_service.dart';
import '../widgets/search_bar_widget.dart';
import '../utils/design_constants.dart';

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
  final DBService _dbService = DBService();

  bool _isFocused = false;
  bool _showWebView = false;
  double _loadingProgress = 0;
  List<String> _suggestions = [];
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _hasPageError = false;

  // Utilisateur connecté
  Map<String, dynamic>? _currentUser;

  // Position de la barre de recherche (haut/bas style Comet)
  bool _isSearchBarBottom = false;
  static const String _searchBarPositionKey = 'search_bar_position';

  // --- MODIFICATIONS POUR LE GROUPE ACTIF ---
  Map<String, dynamic>? _activeGroup;
  bool _isSearchLoading = false;
  static const String _activeGroupKey = 'active_tab_group_id';
  // --- FIN DES MODIFICATIONS ---

  // Reconnaissance vocale
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // Debounce pour les suggestions (évite flood de requêtes)
  Timer? _debounceTimer;
  // Throttle pour _hideGoogleTabs (évite surcharge JS)
  int _lastHideTabsProgress = 0;

  static const String googleSearchUrl = 'https://www.google.com/search?q=';

  @override
  void initState() {
    super.initState();
    _initController();
    _initSpeech();
    _loadSession();
    _loadSearchBarPosition();
    _loadActiveGroup();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
    _searchFade = CurvedAnimation(parent: _animController, curve: const Interval(0.25, 0.75, curve: Curves.easeOut));
    _searchSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic)));
    _actionsFade = CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    _animController.forward();

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (!_isFocused) {
        // Délai pour permettre le clic sur une suggestion avant de vider la liste
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() {
              _suggestions = [];
            });
          }
        });
      }
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

  Future<void> _loadSearchBarPosition() async {
    final position = await _dbService.getSetting(_searchBarPositionKey, 'top');
    if (mounted) {
      setState(() {
        _isSearchBarBottom = position == 'bottom';
      });
    }
  }

  Future<void> _setSearchBarPosition(bool isBottom) async {
    setState(() {
      _isSearchBarBottom = isBottom;
    });
    await _dbService.updateSetting(_searchBarPositionKey, isBottom ? 'bottom' : 'top');
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animController.dispose();
    _focusNode.removeListener(_onFocusChange);
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
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress / 100.0;
            });
            // Throttle : n'injecter le JS que tous les 20% de progression
            if (progress > 10 && progress - _lastHideTabsProgress >= 20) {
              _lastHideTabsProgress = progress;
              _hideGoogleTabs();
            }
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            _hideGoogleTabs();
            _lastHideTabsProgress = 0;

            // Logique de sauvegarde conditionnelle
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
                _isSearchLoading = false;
                _hasPageError = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              // MODIFIÉ: Ignorer les erreurs de ressources (images, scripts, etc.) qui ne sont pas liées au chargement du cadre principal.
              if (error.isForMainFrame == false) {
                return;
              }

              String errorMessage;
              
              // Tente de fournir un message d'erreur plus spécifique basé sur le code d'erreur
              switch (error.errorCode) {
                case -2: // ERROR_HOST_LOOKUP: Échec de la résolution DNS.
                case -6: // ERROR_CONNECT: Échec de la connexion au serveur.
                case -7: // ERROR_TIMEOUT: Temps d'attente dépassé.
                  errorMessage = "Erreur de connexion : Impossible de se connecter au serveur. Vérifiez votre accès Internet.";
                  break;
                case -15: // ERROR_BLOCKED_BY_POLICY: Page bloquée par une politique de sécurité.
                  errorMessage = "Accès bloqué : Cette page est bloquée par une politique de sécurité.";
                  break;
                case -12: // ERROR_BAD_URL: L'URL est invalide.
                  errorMessage = "URL invalide : L'adresse de la page est incorrecte.";
                  break;
                case -1: // ERROR_UNKNOWN: Erreur générique
                default:
                  errorMessage = "Erreur de chargement (${error.errorCode}) : ${error.description.isNotEmpty ? error.description : 'Problème inconnu.'}";
              }

              setState(() {
                _showWebView = true;
                _hasPageError = true;
                _loadingProgress = 0;
                _isSearchLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
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

        /* ===== COUCHE 1 : CSS STRUCTUREL (ne dépend pas des noms de classes) ===== */
        var styleId = 'djim-nuke';
        var css = `
          /* Google classique : header, nav, footer */
          header, #header, #searchform, .sfbg, #top_nav, .fbar, .gb_1,
          div[role="navigation"], nav, footer,
          div[role="banner"] { display:none!important; height:0!important; }
          #main, #rcnt, #cnt, body { margin-top:0!important; top:0!important; }

          /* Lignes / séparateurs */
          .ULSxyf>hr, .kp-blk hr, .mod hr, div[data-attrid]>hr,
          .XqFnDf, .LGOjhe, .wDYxhc hr { display:none!important; border:none!important; }
          .kp-blk,.mod,.wDYxhc,.ULSxyf { border-bottom:none!important; box-shadow:none!important; }

          /* Padding compensation */
          body>div[style*="padding-top"], #search>div[style*="padding-top"],
          #rso>div[style*="padding-top"] { padding-top:0!important; }

          /* Marqueur pour les éléments tués par JS */
          [data-djim-killed] {
            display:none!important; height:0!important; max-height:0!important;
            min-height:0!important; padding:0!important; margin:0!important;
            overflow:hidden!important; visibility:hidden!important;
            pointer-events:none!important; opacity:0!important;
            position:absolute!important; top:-9999px!important;
          }
        `;
        function ensureStyle() {
          var s = document.getElementById(styleId);
          if (!s) { s=document.createElement('style'); s.id=styleId; document.head.appendChild(s); }
          s.textContent = css;
        }
        ensureStyle();

        /* ===== COUCHE 2 : DÉTECTION INTELLIGENTE PAR STRUCTURE (pas par class) ===== */
        function kill(el) {
          if (!el || el.hasAttribute('data-djim-killed')) return;
          el.setAttribute('data-djim-killed', '1');
          el.style.cssText = 'display:none!important;height:0!important;max-height:0!important;overflow:hidden!important;visibility:hidden!important;pointer-events:none!important;position:absolute!important;top:-9999px!important;';
        }

        function isGoogleBar(el) {
          /* Un header Google AI = div en haut de l'écran, étroit, contient SVG/img + bouton */
          if (!el || el.tagName !== 'DIV') return false;
          var rect = el.getBoundingClientRect();
          /* Doit être en haut (top < 10px) et étroit (hauteur < 90px) et large */
          if (rect.top > 10 || rect.height < 5 || rect.height > 90) return false;
          if (rect.width < window.innerWidth * 0.7) return false;
          /* Doit contenir un SVG ou image (logo Google) */
          var hasBrand = el.querySelector('svg, img, a[href*="google"]');
          /* Doit contenir un bouton (fermer) */
          var hasBtn = el.querySelector('button, [role="button"]');
          return !!(hasBrand && hasBtn);
        }

        function nukeAll() {
          ensureStyle();

          /* --- Stratégie A : éléments avec computed position sticky/fixed --- */
          document.querySelectorAll('div, section, aside').forEach(function(el) {
            if (el.hasAttribute('data-djim-killed')) return;
            var cs = window.getComputedStyle(el);
            if (cs.position === 'sticky' || cs.position === 'fixed') {
              var rect = el.getBoundingClientRect();
              /* Seulement les barres en haut, étroites (< 90px de haut) */
              if (rect.top <= 10 && rect.height < 90 && rect.height > 0) {
                kill(el);
              }
            }
          });

          /* --- Stratégie B : attributs style inline sticky --- */
          document.querySelectorAll('[style*="sticky"], [style*="Sticky"]').forEach(function(el) {
            var rect = el.getBoundingClientRect();
            if (rect.top <= 10 && rect.height < 90 && rect.height > 0) {
              kill(el);
            }
          });

          /* --- Stratégie C : détection structurelle (SVG/logo + bouton close en haut) --- */
          document.querySelectorAll('div').forEach(function(el) {
            if (el.hasAttribute('data-djim-killed')) return;
            if (isGoogleBar(el)) {
              kill(el);
            }
          });

          /* --- Stratégie D : boutons close → remonter au parent header --- */
          document.querySelectorAll('button, [role="button"]').forEach(function(btn) {
            if (btn.closest('[data-djim-killed]')) return;
            var lbl = (btn.getAttribute('aria-label')||'') + (btn.textContent||'');
            var isX = /close|fermer|×|✕/i.test(lbl) || (btn.textContent||'').trim().length <= 2 && btn.querySelector('svg');
            if (!isX) return;
            var p = btn;
            for (var i = 0; i < 6; i++) {
              p = p.parentElement;
              if (!p || p === document.body) break;
              var r = p.getBoundingClientRect();
              if (r.top <= 10 && r.height < 90 && r.height > 0 && r.width > window.innerWidth * 0.6) {
                kill(p);
                break;
              }
            }
          });

          /* --- Stratégie E : role="banner" et aria-label Google --- */
          document.querySelectorAll('[role="banner"], [aria-label*="Google"]').forEach(function(el) {
            if (!el.hasAttribute('data-djim-killed')) kill(el);
          });
        }

        /* ===== COUCHE 3 : BOUCLE requestAnimationFrame (filet de sécurité ultime) ===== */
        /* Tourne en continu toutes les ~250ms, ultra léger car on skip les éléments déjà tués */
        if (window._djimRAF) cancelAnimationFrame(window._djimRAF);
        var lastRun = 0;
        function rafLoop(ts) {
          if (ts - lastRun > 250) { lastRun = ts; nukeAll(); }
          window._djimRAF = requestAnimationFrame(rafLoop);
        }
        window._djimRAF = requestAnimationFrame(rafLoop);

        /* ===== COUCHE 4 : MutationObserver (pour les ajouts DOM) ===== */
        if (window._djimObs) window._djimObs.disconnect();
        var mt = null;
        window._djimObs = new MutationObserver(function() {
          if (mt) return;
          mt = setTimeout(function() { mt=null; nukeAll(); }, 50);
        });
        window._djimObs.observe(document.documentElement, {childList:true, subtree:true, attributes:true, attributeFilter:['style','class']});

        /* ===== COUCHE 5 : Scroll listener (sticky headers apparaissent au scroll) ===== */
        if (!window._djimScroll) {
          window._djimScroll = true;
          var st = null;
          window.addEventListener('scroll', function() {
            if (st) return;
            st = setTimeout(function() { st=null; nukeAll(); }, 100);
          }, {passive:true, capture:true});
        }

        /* Exécution immédiate */
        nukeAll();
      })();
    """;
    controller.runJavaScript(jsCode);
  }

  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if ((val == 'done' || val == 'notListening') && mounted) {
              setState(() => _isListening = false);
            }
          },
          onError: (val) {
            if (mounted) setState(() => _isListening = false);
          },
        );
        if (available) {
          if (mounted) setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) {
              if (!mounted) return;
              setState(() {
                _searchController.text = val.recognizedWords;
              });
              if (val.finalResult && val.recognizedWords.isNotEmpty) {
                setState(() => _isListening = false);
                _performSearch(val.recognizedWords);
              }
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            localeId: 'fr_FR',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Accès au microphone refusé"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    // Annuler la requête précédente en cours
    _debounceTimer?.cancel();

    if (query.isEmpty || query.trim().length < 2) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    // Attendre 350ms avant d'envoyer la requête (debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://suggestqueries.google.com/complete/search?client=chrome&hl=fr&q=${Uri.encodeComponent(query.trim())}',
              ),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 && mounted) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (mounted) {
            setState(() => _suggestions = List<String>.from(data[1]).take(7).toList());
          }
        }
      } on TimeoutException {
        // Suggestions non disponibles — ignorer silencieusement
      } catch (_) {
        // Toute autre erreur réseau — ignorer silencieusement
      }
    });
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Annuler tout debounce en cours
    _debounceTimer?.cancel();

    final searchUrl = trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.startsWith('file://')
        ? trimmed
        : '$googleSearchUrl${Uri.encodeComponent(trimmed)}';

    controller.loadRequest(Uri.parse(searchUrl));

    // Ajout conditionnel à l'historique
    if (_activeGroup == null) {
      _dbService.addHistory(trimmed);
    }

    setState(() {
      _showWebView = true;
      _isSearchLoading = true;
      _hasPageError = false;
      _suggestions = [];
      _canGoBack = false;
      _canGoForward = false;
      _lastHideTabsProgress = 0;
    });
    _focusNode.unfocus();
    _appBarFocusNode.unfocus();
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
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Nouveau Groupe d\'Onglets'),
      content: TextField(controller: groupNameController, decoration: const InputDecoration(hintText: 'Nom du groupe', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ANNULER')),
        TextButton(onPressed: () async {
          final name = groupNameController.text.isNotEmpty ? groupNameController.text : 'Groupe sans nom';
          final nav = Navigator.of(dialogContext);
          final messenger = ScaffoldMessenger.of(context);
          await _dbService.addTabGroup(name);
          if (!mounted) return;
          nav.pop();
          messenger.showSnackBar(SnackBar(content: Text('Groupe "$name" créé avec succès.')));
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
    final backButtonColor = backButtonEnabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38);
    final forwardButtonColor = canGoForwardInWeb ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38);

    // Helper pour construire les boutons de navigation (précédent/suivant)
    Widget buildLeadingButtons() {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      );
    }
    
    // Helper pour la barre de recherche en mode petit
    Widget buildTitleContent() {
      return Padding(padding: const EdgeInsets.only(top: 15.0), child: _buildSearchBar(isSmall: true));
    }
    
    // Helper pour les actions/menu
    List<Widget> buildActionsContent() {
      return [Padding(padding: const EdgeInsets.only(top: 15.0, right: 5), child: _buildMainMenu())];
    }

    // ═══════════════════════════════════════════════
    // MODE BAS (style Comet) — Barre de recherche en bas
    // ═══════════════════════════════════════════════
    if (_isSearchBarBottom) {
      return _buildBottomModeLayout(
        colorScheme: colorScheme,
        backButtonEnabled: backButtonEnabled,
        backButtonColor: backButtonColor,
        forwardButtonColor: forwardButtonColor,
        canGoBackInWeb: canGoBackInWeb,
        canGoForwardInWeb: canGoForwardInWeb,
        canPop: canPop,
      );
    }

    // ═══════════════════════════════════════════════
    // MODE HAUT (classique) — Barre de recherche en haut
    // ═══════════════════════════════════════════════
    if (_showWebView) {
      // Structure pour la vue web avec AppBar déroulante (NestedScrollView/SliverAppBar)
      // MODIFIÉ: Remplacement de NestedScrollView par Scaffold + AppBar standard pour garantir le défilement du WebView.
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          // Styles de l'AppBar
          toolbarHeight: 85,
          elevation: 0,
          scrolledUnderElevation: 4,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 90,

          // Contenu de l'AppBar
          leading: buildLeadingButtons(),
          title: buildTitleContent(),
          actions: buildActionsContent(),

          // Barre de progression/Groupe actif
          bottom: _buildAppBarBottom(colorScheme),
        ),
        floatingActionButton: _hasPageError
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _hasPageError = false;
                  _loadingProgress = 0;
                });
                controller.reload();
              },
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              elevation: 2,
              child: const Icon(Icons.refresh_rounded, size: 20),
            )
          : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        // Le corps principal est le WebView avec un espace en bas pour éviter que le contenu soit coupé.
        body: Column(
          children: [
            Expanded(child: WebViewWidget(controller: controller)),
            // Espace en bas pour ne pas que le dernier résultat soit coincé
            SizedBox(height: _hasPageError ? 56 : 16),
          ],
        ),
      );
    } else {
      // Structure pour l'écran d'accueil standard (AppBar fixe)
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 85,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 90,
          
          leading: buildLeadingButtons(),
          title: buildTitleContent(),
          actions: buildActionsContent(),
          
          // La bottom bar est présente uniquement pour le groupe actif sur la page de résultats
          bottom: _buildAppBarBottom(colorScheme),
        ),
        floatingActionButton: null, // Pas de FAB sur l'écran d'accueil
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 85, // 85 = toolbarHeight
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    _buildHomeBody(),
                    // Les suggestions s'affichent par-dessus
                    if (_suggestions.isNotEmpty && _isFocused)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildSuggestionsList(colorScheme),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
            if (!mounted) return;
            if (result != null) {
              if (result is Map<String, dynamic>) {
                _setActiveGroup(result);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Groupe "${result['group_name']}" activé.')));
              } else if (result is String) {
                _searchController.text = result;
                _performSearch(result);
              }
            }
            break;
          case 'clear_group':
            _setActiveGroup(null);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Groupe actif retiré.')));
            break;
          case 'history':
            final selectedQuery = await Navigator.push(context, _slideTransition(const HistoryScreen()));
            if (!mounted) return;
            if (selectedQuery != null && selectedQuery is String) {
              _searchController.text = selectedQuery;
              _performSearch(selectedQuery);
            }
            break;
          case 'downloads': 
            Navigator.push(context, _slideTransition(const DownloadsScreen()));
            break;
          case 'settings':
            await Navigator.push(context, _slideTransition(const SettingsScreen()));
            if (!mounted) return;
            _loadSearchBarPosition(); // Recharger la position au retour des paramètres
            break;
          case 'help': _showHelpOptions(); break;
          case 'about': Navigator.push(context, _slideTransition(const AboutScreen())); break;
          case 'sync':
             if (_currentUser == null) {
                final user = await Navigator.push(context, _slideTransition(const LoginScreen()));
                if (!mounted) return;
                if (user != null && user is Map<String, dynamic>) {
                  await _dbService.saveSession(user['users_id']);
                  if (!mounted) return;
                  setState(() => _currentUser = user);
                }
              } else {
                await _dbService.clearSession();
                if (!mounted) return;
                setState(() => _currentUser = null);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous avez été déconnecté.')));
              }
              break;
          case 'toggle_position':
            _setSearchBarPosition(!_isSearchBarBottom);
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
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'toggle_position',
          child: Row(children: [
            Icon(
              _isSearchBarBottom ? Icons.vertical_align_top_rounded : Icons.vertical_align_bottom_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 22,
            ),
            const SizedBox(width: 15),
            Text(
              _isSearchBarBottom ? 'Barre de recherche en haut' : 'Barre de recherche en bas',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
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

    final double preferredHeight = (hasProgress ? 2.0 : 0.0) + (hasActiveGroup ? 20.0 : 0.0);
    
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
            GestureDetector(
              onTap: () => _setActiveGroup(null),
              child: Container(
                height: 20,
                color: colorScheme.primary.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 6, color: colorScheme.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      _activeGroup!['group_name'].toString(),
                      style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close, size: 10, color: colorScheme.primary.withValues(alpha: 0.4)),
                  ],
                ),
              ),
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
        style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface, side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5))),
      ),
    );
  }

  Widget _buildHomeBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Utiliser l'alignement au lieu de Spacer dans un scroll
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: Spacing.xxxl), // Remplace Spacer(flex: 2)

          // Logo et titre animés
          FadeTransition(
            opacity: _logoFade,
            child: SlideTransition(
              position: _logoSlide,
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/img/logo.png',
                    height: 92,
                    width: 92,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  // Titre "DjimSearch"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Djim',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Search',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.xxxl),

          // Barre de recherche animée
          FadeTransition(
            opacity: _searchFade,
            child: SlideTransition(
              position: _searchSlide,
              child: _buildSearchBar(isSmall: false),
            ),
          ),

          // Groupe actif (badge)
          if (_activeGroup != null && !_showWebView)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(Spacing.radiusRound),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: Spacing.md),
                    Text(
                      'Groupe actif: ${_activeGroup!['group_name']}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    InkWell(
                      onTap: () => _setActiveGroup(null),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),


          const SizedBox(height: Spacing.xxxl),
          const SizedBox(height: Spacing.lg),
        ],
      ),
    );
  }


  Widget _buildSearchBar({required bool isSmall}) {
    // En mode bottom, toujours utiliser _focusNode pour la cohérence
    FocusNode currentFocusNode = isSmall && !_showWebView && !_isSearchBarBottom ? _appBarFocusNode : _focusNode;

    final searchBar = SearchBarWidget(
      controller: _searchController,
      focusNode: currentFocusNode,
      onChanged: (value) {
        _fetchSuggestions(value);
        setState(() {});
      },
      onSubmitted: _performSearch,
      onMicPressed: _listen,
      isSmall: isSmall,
      isListening: _isListening,
      showMicButton: true,
    );


    return searchBar;
  }


  // ═══════════════════════════════════════════════════════════════
  // LAYOUT MODE BAS (style Comet) — Barre de recherche en bas
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomModeLayout({
    required ColorScheme colorScheme,
    required bool backButtonEnabled,
    required Color backButtonColor,
    required Color forwardButtonColor,
    required bool canGoBackInWeb,
    required bool canGoForwardInWeb,
    required bool canPop,
  }) {
    final theme = Theme.of(context);

    // Boutons de navigation pour la barre du bas
    Widget navButtons = Row(mainAxisSize: MainAxisSize.min, children: [
      _buildNavButton(Icons.arrow_back_rounded, backButtonColor, backButtonEnabled ? () {
        if (canGoBackInWeb) {
          controller.goBack();
        } else {
          Navigator.pop(context);
        }
      } : null, 'Retour'),
      const SizedBox(width: 4),
      _buildNavButton(Icons.arrow_forward_rounded, forwardButtonColor, canGoForwardInWeb ? () => controller.goForward() : null, 'Suivant'),
    ]);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      floatingActionButton: _showWebView && _hasPageError
        ? FloatingActionButton.small(
            onPressed: () {
              setState(() { _hasPageError = false; _loadingProgress = 0; });
              controller.reload();
            },
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            elevation: 2,
            child: const Icon(Icons.refresh_rounded, size: 20),
          )
        : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre de progression en haut
            if (_showWebView && _loadingProgress > 0 && _loadingProgress < 1)
              LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 2,
              ),
            // Indicateur de groupe actif en haut (mode WebView)
            if (_showWebView && _activeGroup != null)
              GestureDetector(
                onTap: () => _setActiveGroup(null),
                child: Container(
                  height: 24,
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fiber_manual_record, size: 6, color: colorScheme.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        _activeGroup!['group_name'].toString(),
                        style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.close, size: 10, color: colorScheme.primary.withValues(alpha: 0.4)),
                    ],
                  ),
                ),
              ),
            // Contenu principal
            Expanded(
              child: _showWebView
                ? WebViewWidget(controller: controller)
                : _buildBottomHomeBody(theme, colorScheme),
            ),
            // Barre du bas (dans le body pour que le clavier la pousse vers le haut)
            _buildBottomBar(colorScheme, navButtons),
          ],
        ),
      ),
    );
  }

  /// Barre du bas style Comet : navigation + recherche + menu
  Widget _buildBottomBar(ColorScheme colorScheme, Widget navButtons) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestions au-dessus de la barre de recherche (mode bottom)
            if (_suggestions.isNotEmpty && _isFocused)
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) => _buildSuggestionTile(
                    _suggestions[index],
                    colorScheme,
                    index == _suggestions.length - 1,
                  ),
                ),
              ),
            // Séparateur subtil
            Divider(height: 1, thickness: 0.5, color: colorScheme.outline.withValues(alpha: 0.1)),
            // Barre principale
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  navButtons,
                  const SizedBox(width: 8),
                  Expanded(child: _buildSearchBar(isSmall: true)),
                  _buildMainMenu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Corps de l'écran d'accueil en mode bottom (sans logo, épuré)
  Widget _buildBottomHomeBody(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: Spacing.xxxl),

              // Groupe actif (badge)
              if (_activeGroup != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xxxl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(Spacing.radiusRound),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: Spacing.md),
                        Text(
                          'Groupe actif: ${_activeGroup!['group_name']}',
                          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: Spacing.md),
                        InkWell(
                          onTap: () => _setActiveGroup(null),
                          child: Icon(Icons.close, size: 18, color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),

              // Icône et indication subtile
              Icon(
                Icons.search_rounded,
                size: 72,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Recherchez depuis la barre ci-dessous',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xxl),


              const SizedBox(height: Spacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGETS PARTAGÉS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSuggestionsList(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(Spacing.radiusRound),
              bottomRight: Radius.circular(Spacing.radiusRound),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              left: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
              right: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
              bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) => _buildSuggestionTile(
              _suggestions[index],
              colorScheme,
              index == _suggestions.length - 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Construit une suggestion élégante avec animation au hover
  Widget _buildSuggestionTile(
    String suggestion,
    ColorScheme colorScheme,
    bool isLast,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = suggestion;
          _performSearch(suggestion);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Text(
                  suggestion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Icon(
                Icons.arrow_outward,
                size: 16,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




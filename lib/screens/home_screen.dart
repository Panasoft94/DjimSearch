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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _appBarFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  bool _isFocused = false;
  bool _showWebView = false;
  double _loadingProgress = 0;
  List<String> _suggestions = [];
  bool _canGoBack = false;
  bool _canGoForward = false;

  // Reconnaissance vocale
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  static const String googleSearchUrl = 'https://www.google.com/search?q=';

  @override
  void initState() {
    super.initState();
    _initController();
    _initSpeech();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

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
      ..setBackgroundColor(Colors.white)
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
    """;
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
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700], size: 22),
          const SizedBox(width: 15),
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : Colors.black87)),
        ],
      ),
    );
  }

  void _showHelpOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              child: Text('Aide et commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
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
    final bool canPop = Navigator.of(context).canPop();
    final bool canGoBackInWeb = _showWebView && _canGoBack;
    final bool canGoForwardInWeb = _showWebView && _canGoForward;
    
    final backButtonEnabled = canGoBackInWeb || canPop;
    final backButtonColor = backButtonEnabled ? Colors.grey[700] : Colors.grey[500];
    final forwardButtonColor = canGoForwardInWeb ? Colors.grey[700] : Colors.grey[500];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 85,
        elevation: 0,
        backgroundColor: const Color(0xFFF7F7F7),
        shape: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 90, // Réduit encore pour gagner quelques pixels (40+40+8=88)
        leading: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4), // Marge gauche minimale
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back_rounded, color: backButtonColor, size: 24),
                  onPressed: backButtonEnabled ? () {
                    if (canGoBackInWeb) {
                      controller.goBack();
                    } else {
                      Navigator.pop(context);
                    }
                  } : null,
                  tooltip: 'Retour',
                ),
              ),
              const SizedBox(width: 4), // Espace réduit entre les flèches
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_forward_rounded, color: forwardButtonColor, size: 24),
                  onPressed: canGoForwardInWeb ? () => controller.goForward() : null,
                  tooltip: 'Suivant',
                ),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0), // Plus de padding horizontal
          child: _buildSearchBar(isSmall: true),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black87, size: 28),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              onSelected: (value) {
                switch (value) {
                  case 'new_tab':
                    Navigator.push(context, _slideTransition(const HomeScreen()));
                    break;
                  case 'new_group':
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nouveau groupe (À venir)')));
                    break;
                  case 'history':
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Historique (À venir)')));
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
                    Navigator.push(context, _slideTransition(const LoginScreen()));
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
                _buildPopupItem('Connexion / Sync', Icons.sync_rounded, 'sync'),
                const PopupMenuDivider(),
                _buildPopupItem('Quitter', Icons.power_settings_new_rounded, 'exit', isDestructive: true),
              ],
            ),
          ),
          const SizedBox(width: 5),
        ],
        bottom: _loadingProgress > 0 && _loadingProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : null,
      ),
      floatingActionButton: _showWebView 
          ? FloatingActionButton(
              onPressed: () => controller.reload(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.refresh, color: Colors.white),
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
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    border: const Border(left: BorderSide(color: Color(0xFFE0E0E0)), right: BorderSide(color: Color(0xFFE0E0E0)), bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 5, bottom: 10),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history, size: 20, color: Colors.grey),
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

  Widget _buildHomeBody() {
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
                    const Spacer(flex: 3), // Pousse le contenu vers le centre
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Djim', style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.blue[700], letterSpacing: -2)),
                        Text('Search', style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.red[400], letterSpacing: -2)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildSearchBar(isSmall: false),
                      ),
                    ),
                    const SizedBox(height: 30),

                    IgnorePointer(
                      ignoring: hideButtons,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: hideButtons ? 0.0 : 1.0,
                        child: Wrap(
                          spacing: 20,
                          children: [
                            _buildQuickAction('Google', Icons.public, Colors.blue),
                            _buildQuickAction('Images', Icons.image, Colors.red),
                            _buildQuickAction('Actu', Icons.newspaper, Colors.orange),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 4), // Pousse le footer vers le bas

                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Copyright © Panasoft Corporation',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
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
    bool showSuggestions = _suggestions.isNotEmpty && _isFocused && !isSmall;

    FocusNode currentFocusNode;
    if (isSmall && !_showWebView) {
      currentFocusNode = _appBarFocusNode;
    } else {
      currentFocusNode = _focusNode;
    }

    Widget searchBar = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isSmall ? 45 : 55,
      decoration: BoxDecoration(
        color: isSmall ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30),
          topRight: const Radius.circular(30),
          bottomLeft: Radius.circular(showSuggestions ? 0 : 30),
          bottomRight: Radius.circular(showSuggestions ? 0 : 30),
        ),
        border: Border.all(
          color: (isSmall && !_showWebView ? _appBarFocusNode.hasFocus : _isFocused) ? Colors.blue : Colors.grey[300]!,
          width: 1.2,
        ),
        boxShadow: isSmall ? [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))
        ] : null,
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
        decoration: InputDecoration(
          hintText: 'Rechercher ou saisir une URL',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
          suffixIcon: IconButton(
            icon: Icon(
              _isListening ? Icons.graphic_eq_rounded : Icons.mic, 
              color: _isListening ? Colors.red : Colors.blue, 
              size: 20
            ),
            onPressed: _listen,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _performSearch(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(4),
    );
  }
}
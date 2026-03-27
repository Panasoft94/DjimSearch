import 'package:flutter/material.dart';
import 'create_account_screen.dart';
import '../db_service.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DBService _dbService = DBService();

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _buttonFade;

  bool _obscureText = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    _formFade = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOut));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
    );

    _buttonFade = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  PageRouteBuilder _slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = await _dbService.authenticateUser(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Bienvenue ${user['users_prenom']} ! 👋')),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, user);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Email ou mot de passe incorrect.')),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  void _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 48),
        title: const Text('Réinitialiser ?'),
        content: const Text(
          'Toutes les données seront supprimées. Cette action est irréversible.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('RÉINITIALISER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.resetDB();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Base de données réinitialisée.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: false,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomBackButton(onPressed: () => Navigator.pop(context)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: Spacing.xl),

                    // Logo et titre
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/img/logo.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: Spacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Djim', style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                Text('Search', style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              ],
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(
                              'Connectez-vous pour synchroniser',
                              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.xxxl + 8),

                    // Formulaire dans une Card stylisée
                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.login_rounded, color: colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Identifiants', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: _buildInputDecoration(
                                    hintText: 'votre.email@exemple.com',
                                    prefixIcon: Icons.email_outlined,
                                    colorScheme: colorScheme,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'L\'email est requis';
                                    if (!value.contains('@') || !value.contains('.')) return 'Email invalide';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Votre mot de passe',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    colorScheme: colorScheme,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () => setState(() => _obscureText = !_obscureText),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Le mot de passe est requis';
                                    if (value.length < 6) return 'Au moins 6 caractères';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Boutons
                    FadeTransition(
                      opacity: _buttonFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, color: colorScheme.onPrimary, size: 20),
                                        const SizedBox(width: 10),
                                        Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Séparateur
                          Row(
                            children: [
                              Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OU', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                              ),
                              Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.2))),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(context, _slideTransition(const CreateAccountScreen())),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_outlined, color: colorScheme.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Créer un compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: TextButton.icon(
                              onPressed: _resetDatabase,
                              icon: Icon(Icons.restart_alt_rounded, size: 16, color: colorScheme.error.withValues(alpha: 0.7)),
                              label: Text(
                                'Réinitialiser la base de données',
                                style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.error.withValues(alpha: 0.7)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Spacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


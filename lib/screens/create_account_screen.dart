import 'package:flutter/material.dart';
import '../db_service.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> with SingleTickerProviderStateMixin {
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
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
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
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final existingUser = await _dbService.getUserByEmail(_emailController.text.trim());
      if (mounted) {
        if (existingUser != null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Cet email est déjà utilisé.')),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          return;
        }

        final newUser = {
          'users_nom': _nomController.text.trim(),
          'users_prenom': _prenomController.text.trim(),
          'users_email': _emailController.text.trim(),
          'users_password': _passwordController.text,
        };

        try {
          await _dbService.createUser(newUser);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Compte créé avec succès ! 🎉')),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${e.toString()}'),
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
                    const SizedBox(height: Spacing.lg),

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
                              child: Image.asset('assets/img/logo.png', height: 72, width: 72, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Djim', style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                Text('Search', style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text('Créer votre compte', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: Spacing.xxxl),

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
                                // Titre section
                                Row(
                                  children: [
                                    Icon(Icons.person_add_rounded, color: colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Informations personnelles', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Nom et Prénom côte à côte
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nomController,
                                        textInputAction: TextInputAction.next,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: _buildInputDecoration(
                                          hintText: 'Nom',
                                          prefixIcon: Icons.badge_outlined,
                                          colorScheme: colorScheme,
                                        ),
                                        validator: (value) => value?.trim().isEmpty ?? true ? 'Requis' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _prenomController,
                                        textInputAction: TextInputAction.next,
                                        textCapitalization: TextCapitalization.words,
                                        decoration: _buildInputDecoration(
                                          hintText: 'Prénom',
                                          prefixIcon: Icons.person_outline_rounded,
                                          colorScheme: colorScheme,
                                        ),
                                        validator: (value) => value?.trim().isEmpty ?? true ? 'Requis' : null,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Email
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
                                    if (value?.trim().isEmpty ?? true) return 'Email requis';
                                    if (!value!.contains('@') || !value.contains('.')) return 'Email invalide';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Mot de passe
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _buildInputDecoration(
                                    hintText: 'Au moins 6 caractères',
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
                                    if (value?.isEmpty ?? true) return 'Mot de passe requis';
                                    if (value!.length < 6) return 'Au moins 6 caractères';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Indicateur de force du mot de passe
                                _buildPasswordStrengthIndicator(
                                  _getPasswordStrength(_passwordController.text),
                                  colorScheme,
                                  theme,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Bouton d'inscription
                    FadeTransition(
                      opacity: _buttonFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
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
                                        Icon(Icons.how_to_reg_rounded, color: colorScheme.onPrimary, size: 20),
                                        const SizedBox(width: 10),
                                        Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Lien vers connexion
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                  children: [
                                    const TextSpan(text: 'Déjà un compte ? '),
                                    TextSpan(
                                      text: 'Se connecter',
                                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
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

  Widget _buildPasswordStrengthIndicator(int strength, ColorScheme colorScheme, ThemeData theme) {
    final strengthTexts = ['', 'Faible', 'Moyen', 'Bon', 'Excellent'];
    final strengthColors = [Colors.grey, Colors.red, Colors.orange, Colors.lightGreen, Colors.green];
    final strengthIcons = [null, Icons.sentiment_very_dissatisfied, Icons.sentiment_neutral, Icons.sentiment_satisfied, Icons.sentiment_very_satisfied];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index < strength ? strengthColors[strength] : colorScheme.outline.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          if (strength > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(strengthIcons[strength], size: 16, color: strengthColors[strength]),
                const SizedBox(width: 6),
                Text(
                  'Force : ${strengthTexts[strength]}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: strengthColors[strength],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

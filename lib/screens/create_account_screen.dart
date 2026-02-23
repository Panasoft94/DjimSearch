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
    if (password.length < 6) return 1;
    if (password.length < 10) return 2;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[0-9]').hasMatch(password)) return 4;
    return 3;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final existingUser = await _dbService.getUserByEmail(_emailController.text);
      if (mounted) {
        if (existingUser != null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: Cet email est déjà utilisé.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
          );
          return;
        }

        final newUser = {
          'users_nom': _nomController.text,
          'users_prenom': _prenomController.text,
          'users_email': _emailController.text,
          'users_password': _passwordController.text,
        };

        try {
          await _dbService.createUser(newUser);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compte créé avec succès !'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: CustomBackButton(onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: Spacing.xxxl),
            FadeTransition(
              opacity: _logoFade,
              child: SlideTransition(
                position: _logoSlide,
                child: Column(children: [
                  Image.asset('assets/img/logo.png', height: 80, width: 80, fit: BoxFit.contain),
                  const SizedBox(height: Spacing.lg),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Djim', style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                    Text('Search', style: theme.textTheme.displayMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: Spacing.sm),
                  Text('Créer un compte', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                ]),
              ),
            ),
            const SizedBox(height: Spacing.xxxl),
            FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nom', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        hintText: 'Votre nom',
                        prefixIcon: Icon(Icons.person_rounded, color: colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Le nom est requis' : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text('Prénom', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _prenomController,
                      decoration: InputDecoration(
                        hintText: 'Votre prénom',
                        prefixIcon: Icon(Icons.person_rounded, color: colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Le prénom est requis' : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text('Email', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'votre.email@exemple.com',
                        prefixIcon: Icon(Icons.email_rounded, color: colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Email requis';
                        if (!value!.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text('Mot de passe', style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(height: Spacing.sm),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Au moins 6 caractères',
                        prefixIcon: Icon(Icons.lock_rounded, color: colorScheme.primary),
                        suffixIcon: IconButton(icon: Icon(_obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colorScheme.primary), onPressed: () => setState(() => _obscureText = !_obscureText)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Mot de passe requis';
                        if (value!.length < 6) return 'Au moins 6 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.md),
                    _buildPasswordStrengthIndicator(_getPasswordStrength(_passwordController.text), colorScheme, theme),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xxxl),
            FadeTransition(
              opacity: _buttonFade,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: Spacing.lg), backgroundColor: colorScheme.primary, disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5)),
                  child: _isLoading ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) : const Text('Créer un compte'),
                ),
              ]),
            ),
            const SizedBox(height: Spacing.xxxl),
          ]),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(int strength, ColorScheme colorScheme, ThemeData theme) {
    final strengthTexts = ['', 'Faible', 'Moyen', 'Bon', 'Excellent'];
    final strengthColors = [Colors.grey, Colors.red, Colors.orange, Colors.yellow, Colors.green];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? Spacing.xs : 0),
                decoration: BoxDecoration(color: index < strength ? strengthColors[strength] : Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            );
          }),
        ),
        const SizedBox(height: Spacing.sm),
        if (strength > 0) Text('Force: ${strengthTexts[strength]}', style: theme.textTheme.labelSmall?.copyWith(color: strengthColors[strength], fontWeight: FontWeight.w600)),
      ],
    );
  }
}


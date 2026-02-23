import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _logoSlide;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),

            // ── Logo + Nom + Badge Version ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _logoSlide,
                child: Card(
                  elevation: Elevations.medium,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.primaryContainer.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Logo avec ombre
                        Container(
                          padding: const EdgeInsets.all(Spacing.lg),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
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
                        // Nom de l'app
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Djim',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Search',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.xl),
                        // ── Badge Version PRODUCTION READY - Très visible ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1B5E20),
                                const Color(0xFF2E7D32),
                                const Color(0xFF388E3C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(Spacing.radiusLarge),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.md),
                                  Text(
                                    'VERSION STABLE',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.4,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(Spacing.radiusRound),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF69F0AE).withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Text(
                                      'Version 1.0.0',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: const Color(0xFF1B5E20),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // ── Contenu animé ──
            SlideTransition(
              position: _contentSlide,
              child: Column(
                children: [
                  // Card Description - Stylisée
                  Card(
                    elevation: Elevations.medium,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.surface,
                            colorScheme.primaryContainer.withValues(alpha: isDark ? 0.1 : 0.08),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(Spacing.md),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.rocket_launch_rounded,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Text(
                              'Moteur de recherche moderne,\nrapide et intelligent',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.tertiary],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Text(
                              'DjimSearch vous offre une expérience de navigation intuitive avec recherche vocale, historique intelligent et synchronisation en cloud.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  // Card Fonctionnalités - Stylisée
                  Card(
                    elevation: Elevations.medium,
                    shadowColor: colorScheme.tertiary.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                      side: BorderSide(
                        color: colorScheme.tertiary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.surface,
                            colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.08 : 0.06),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(Spacing.sm),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary.withValues(alpha: 0.15),
                                        colorScheme.tertiary.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Text(
                                    'Fonctionnalités',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(Spacing.radiusRound),
                                  ),
                                  child: Text(
                                    '4',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.lg),
                            _buildFeaturesList(theme, colorScheme, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.lg),

                  // Card Développeur - Stylisée
                  Card(
                    elevation: Elevations.medium,
                    shadowColor: colorScheme.secondary.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                      side: BorderSide(
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            colorScheme.surface,
                            colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.08 : 0.06),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.code_rounded,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Text(
                                  'Développé par',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(Spacing.lg),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(Spacing.sm),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(Spacing.radiusSmall),
                                        ),
                                        child: Icon(
                                          Icons.business_rounded,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: Spacing.md),
                                      Expanded(
                                        child: Text(
                                          'Panasoft Corporation',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: Spacing.md),
                                  Divider(
                                    color: colorScheme.outline.withValues(alpha: 0.15),
                                    height: 1,
                                  ),
                                  const SizedBox(height: Spacing.md),
                                  Text(
                                    '© 2024-2026 · Tous droits réservés',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Spacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final features = [
      (Icons.search_rounded, 'Recherche web', 'Accédez à Google, Bing et plus'),
      (Icons.mic_rounded, 'Recherche vocale', 'Dictez votre requête'),
      (Icons.devices_rounded, 'Design responsif', 'Optimisé pour tous appareils'),
      (Icons.cloud_sync_rounded, 'Synchronisation', 'Vos données en cloud'),
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        final isLast = index == features.length - 1;

        return Column(
          children: [
            Card(
              elevation: Elevations.small,
              shadowColor: colorScheme.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.25 : 0.35),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                      ),
                      child: Icon(
                        feature.$1,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.$2,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            feature.$3,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Spacing.radiusSmall),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast) const SizedBox(height: Spacing.sm),
          ],
        );
      }).toList(),
    );
  }
}


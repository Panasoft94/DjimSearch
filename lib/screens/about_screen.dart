import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _heroSlide;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
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
        scrolledUnderElevation: 0,
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'À propos',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.sm),
            // ── Hero ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _heroSlide,
                child: _buildHeroCard(theme, colorScheme),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // ── Contenu ──
            SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildMissionCard(theme, colorScheme),
                    const SizedBox(height: Spacing.lg),
                    _buildFeaturesCard(theme, colorScheme),
                    const SizedBox(height: Spacing.lg),
                    _buildPillarsCard(theme, colorScheme),
                    const SizedBox(height: Spacing.lg),
                    _buildDeveloperCard(theme, colorScheme, isDark),
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

  // ═══════════════════════════════════════════════════════════════════
  // HERO CARD — En-tête premium avec logo et version
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFF2B8AFF), Color(0xFF1565D8), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565D8).withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          vertical: Spacing.xxl + 4, horizontal: Spacing.xl),
      child: Column(
        children: [
          // Logo avec halo animé
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(Spacing.lg + 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.10),
                        blurRadius: 24,
                        spreadRadius: 6),
                  ],
                ),
                child: Image.asset('assets/img/logo.png',
                    height: 72, width: 72, fit: BoxFit.contain),
              ),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Titre DjimSearch
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Djim',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'Search',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ]),
          ),

          const SizedBox(height: Spacing.md),

          // Sous-titre
          Text(
            'Votre navigateur intelligent & moderne',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0.2,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Spacing.xl),

          // Badge version épuré
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg + 4, vertical: Spacing.sm + 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Spacing.radiusRound),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                          blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'v1.0.0',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  '·',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Stable',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MISSION CARD — Vision et description
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMissionCard(ThemeData theme, ColorScheme colorScheme) {
    return _buildCard(
      colorScheme: colorScheme,
      child: Column(
        children: [
          Row(
            children: [
              _buildIconBadge(
                Icons.rocket_launch_rounded,
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.10),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'Notre vision',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [colorScheme.primary, const Color(0xFFEA4335)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'DjimSearch réinvente la navigation mobile avec une approche centrée sur vous. '
            'Recherche vocale intuitive, groupes d\'onglets pour organiser vos sessions, '
            'historique intelligent et synchronisation cloud — le tout dans une interface '
            'fluide et élégante.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.75,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          // Citation inspirante
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg, vertical: Spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(Spacing.radiusMedium),
              border: Border(
                left: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 3),
              ),
            ),
            child: Text(
              '« Naviguer devrait être simple, rapide et agréable. »',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURES CARD — Fonctionnalités en grille 2 colonnes
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeaturesCard(ThemeData theme, ColorScheme colorScheme) {
    final features = [
      _FeatureItem(Icons.search_rounded, 'Recherche web',
          'Google & URLs', const Color(0xFF1F7FFF)),
      _FeatureItem(Icons.mic_rounded, 'Recherche vocale',
          'Dictez en français', const Color(0xFFEA4335)),
      _FeatureItem(Icons.folder_copy_rounded, 'Groupes d\'onglets',
          'Organisez vos sessions', const Color(0xFFFBBC04)),
      _FeatureItem(Icons.history_rounded, 'Historique',
          'Retrouvez tout', const Color(0xFF34A853)),
      _FeatureItem(Icons.cloud_sync_rounded, 'Sync. cloud',
          'Toujours disponible', const Color(0xFF00BCD4)),
      _FeatureItem(Icons.shield_rounded, 'Vie privée',
          'Navigation sécurisée', const Color(0xFF7C4DFF)),
    ];

    return _buildCard(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(
                Icons.auto_awesome_rounded,
                const Color(0xFFF8A804),
                const Color(0xFFFBBC04).withValues(alpha: 0.12),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'Fonctionnalités',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm + 2, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Spacing.radiusRound),
                ),
                child: Text(
                  '${features.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          // Grille 2 colonnes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.sm + 2,
              crossAxisSpacing: Spacing.sm + 2,
              childAspectRatio: 1.55,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final f = features[index];
              return Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                  border: Border.all(color: f.color.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: f.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(Spacing.radiusMedium),
                      ),
                      child: Icon(f.icon, color: f.color, size: 18),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      f.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PILLARS CARD — Pourquoi DjimSearch (3 piliers)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPillarsCard(ThemeData theme, ColorScheme colorScheme) {
    final pillars = [
      (
        Icons.bolt_rounded,
        'Rapide',
        'Résultats instantanés, interface fluide sans latence.',
        const Color(0xFFFBBC04),
      ),
      (
        Icons.lock_rounded,
        'Sécurisé',
        'Vos données restent sur votre appareil, navigation protégée.',
        const Color(0xFF34A853),
      ),
      (
        Icons.touch_app_rounded,
        'Intuitif',
        'Conçu pour une prise en main immédiate, zéro complexité.',
        const Color(0xFF1F7FFF),
      ),
    ];

    return _buildCard(
      colorScheme: colorScheme,
      child: Column(
        children: [
          Row(
            children: [
              _buildIconBadge(
                Icons.diamond_rounded,
                const Color(0xFF7C4DFF),
                const Color(0xFF7C4DFF).withValues(alpha: 0.10),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'Pourquoi DjimSearch ?',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          ...pillars.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < pillars.length - 1 ? Spacing.md : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.$4.withValues(alpha: 0.10),
                      border:
                          Border.all(color: p.$4.withValues(alpha: 0.20)),
                    ),
                    child: Icon(p.$1, color: p.$4, size: 20),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.$2,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.$3,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DEVELOPER CARD — Développeur / Éditeur
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDeveloperCard(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer
                .withValues(alpha: isDark ? 0.30 : 0.45),
            colorScheme.secondaryContainer
                .withValues(alpha: isDark ? 0.20 : 0.30),
          ],
        ),
        border:
            Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.business_center_rounded,
                color: colorScheme.primary, size: 30),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Panasoft Corporation',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '© 2024–${DateTime.now().year} · Tous droits réservés',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          // Badges de confiance
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _buildTrustBadge(theme, colorScheme, Icons.verified_rounded,
                  'Certifiée', const Color(0xFF34A853)),
              _buildTrustBadge(theme, colorScheme, Icons.security_rounded,
                  'Sécurisée', const Color(0xFF1F7FFF)),
              _buildTrustBadge(theme, colorScheme, Icons.content_paste_go_outlined,
                  'République Centrafricaine', const Color(0xFFEA4335)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS — Composants réutilisables
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCard(
      {required ColorScheme colorScheme, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconBadge(IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm + 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Spacing.radiusMedium),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTrustBadge(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Spacing.radiusRound),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 15),
          const SizedBox(width: Spacing.xs + 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modèle interne pour les fonctionnalités
class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureItem(this.icon, this.title, this.subtitle, this.color);
}

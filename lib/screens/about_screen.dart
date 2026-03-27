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
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
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
        leading: CustomBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'À propos',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.md),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _heroSlide,
                child: _buildHeroCard(theme, colorScheme),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildDescriptionCard(theme, colorScheme),
                    const SizedBox(height: Spacing.md),
                    _buildFeaturesCard(theme, colorScheme),
                    const SizedBox(height: Spacing.md),
                    _buildTechCard(theme, colorScheme),
                    const SizedBox(height: Spacing.md),
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

  // ─── HERO CARD ──────────────────────────────────────────────────────
  Widget _buildHeroCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F7FFF), Color(0xFF0052CC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F7FFF).withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl, horizontal: Spacing.xl),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: Image.asset('assets/img/logo.png', height: 76, width: 76, fit: BoxFit.contain),
          ),

          const SizedBox(height: Spacing.xl),

          // Titre
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Djim',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'Search',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w900, letterSpacing: -1,
                ),
              ),
            ]),
          ),

          const SizedBox(height: Spacing.xl),

          // ── BADGE VERSION — Ultra visible ──
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Spacing.radiusRound),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(color: Color(0xFF34A853), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0052CC),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853),
                        borderRadius: BorderRadius.circular(Spacing.radiusRound),
                      ),
                      child: Text(
                        'PROD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w900,
                          letterSpacing: 1.2, fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: Spacing.lg),

          Text(
            'Moteur de recherche intelligent & moderne',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── DESCRIPTION ────────────────────────────────────────────────────
  Widget _buildDescriptionCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: Elevations.small,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.radiusMedium),
              ),
              child: Icon(Icons.rocket_launch_rounded, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(width: Spacing.md),
            Text('Notre mission', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: Spacing.lg),
          Container(
            width: 36, height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.error]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'DjimSearch vous offre une expérience de navigation intuitive avec recherche vocale, historique intelligent, groupes d\'onglets et synchronisation en cloud. Conçu pour être rapide, fluide et agréable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant, height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  // ─── FONCTIONNALITÉS ────────────────────────────────────────────────
  Widget _buildFeaturesCard(ThemeData theme, ColorScheme colorScheme) {
    final features = [
      (Icons.search_rounded, 'Recherche web', 'Google & URLs directes', const Color(0xFF1F7FFF)),
      (Icons.mic_rounded, 'Recherche vocale', 'Dictez votre requête en français', const Color(0xFFEA4335)),
      (Icons.folder_copy_rounded, 'Groupes d\'onglets', 'Organisez vos sessions', const Color(0xFFFBBC04)),
      (Icons.history_rounded, 'Historique intelligent', 'Retrouvez vos recherches', const Color(0xFF34A853)),
      (Icons.cloud_sync_rounded, 'Sync. cloud', 'Vos données toujours disponibles', const Color(0xFF00BCD4)),
    ];

    return Card(
      elevation: Elevations.small,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBC04).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Spacing.radiusMedium),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF8A804), size: 22),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text('Fonctionnalités',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.radiusRound),
              ),
              child: Text('${features.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary, fontWeight: FontWeight.w800,
                  )),
            ),
          ]),
          const SizedBox(height: Spacing.lg),
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < features.length - 1 ? Spacing.sm : 0),
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: f.$4.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                  border: Border.all(color: f.$4.withValues(alpha: 0.18)),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: f.$4.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                    ),
                    child: Icon(f.$1, color: f.$4, size: 20),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.$2, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(f.$3,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  Icon(Icons.check_circle_rounded, color: f.$4, size: 18),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  // ─── TECHNOLOGIES ────────────────────────────────────────────────────
  Widget _buildTechCard(ThemeData theme, ColorScheme colorScheme) {
    final techs = [
      ('Flutter', Icons.flutter_dash_rounded, const Color(0xFF02569B)),
      ('Dart', Icons.code_rounded, const Color(0xFF0175C2)),
      ('SQLite', Icons.storage_rounded, const Color(0xFF34A853)),
      ('WebView', Icons.web_rounded, const Color(0xFF1F7FFF)),
    ];

    return Card(
      elevation: Elevations.small,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF02569B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Spacing.radiusMedium),
              ),
              child: const Icon(Icons.developer_mode_rounded, color: Color(0xFF02569B), size: 22),
            ),
            const SizedBox(width: Spacing.md),
            Text('Technologies utilisées',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: Spacing.lg),
          Row(
            children: techs.map((t) {
              final isLast = t == techs.last;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : Spacing.sm),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.xs),
                  decoration: BoxDecoration(
                    color: t.$3.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(Spacing.radiusMedium),
                    border: Border.all(color: t.$3.withValues(alpha: 0.2)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(t.$2, color: t.$3, size: 26),
                    const SizedBox(height: 6),
                    Text(t.$1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: t.$3, fontWeight: FontWeight.w800, fontSize: 10,
                        ),
                        textAlign: TextAlign.center),
                  ]),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  // ─── DÉVELOPPEUR ────────────────────────────────────────────────────
  Widget _buildDeveloperCard(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacing.radiusXLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.55),
            colorScheme.secondaryContainer.withValues(alpha: isDark ? 0.25 : 0.35),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Icon(Icons.business_center_rounded, color: colorScheme.primary, size: 32),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Panasoft Corporation',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900, color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '© 2024–2026 · Tous droits réservés',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Spacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(Spacing.radiusRound),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF34A853), size: 18),
            const SizedBox(width: Spacing.sm),
            Text(
              'Application certifiée & sécurisée',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600, color: colorScheme.onSurface,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}


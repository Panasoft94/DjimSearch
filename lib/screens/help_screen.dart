import 'package:flutter/material.dart';
import '../widgets/custom_back_button.dart';
import '../utils/design_constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Aide et Support'),
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 2,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomBackButton(onPressed: () => Navigator.pop(context)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.lg),
                  _buildAnimatedItem(index: 0, child: _buildFeatureCard(icon: Icons.new_releases_rounded, color: Colors.purple, title: 'Nouveautés', subtitle: 'Version 1.0.0 - Ce qui a changé', onTap: () => _showChangelog(context))),
                  _buildAnimatedItem(index: 1, child: _buildFeatureCard(icon: Icons.help_outline_rounded, color: Colors.blue, title: 'Questions fréquentes', subtitle: 'Réponses rapides à vos interrogations', onTap: () => _showFAQ(context))),
                  _buildAnimatedItem(index: 2, child: _buildFeatureCard(icon: Icons.bug_report_rounded, color: Colors.orange, title: 'Signaler un problème', subtitle: 'Aidez-nous à améliorer l\'application', onTap: () => _showReportDialog(context))),
                  _buildAnimatedItem(index: 3, child: _buildFeatureCard(icon: Icons.alternate_email_rounded, color: Colors.teal, title: 'Nous contacter', subtitle: 'Besoin d\'une assistance directe ?', onTap: () => _showContactOptions(context))),
                  const SizedBox(height: Spacing.xxxl),
                  _buildAnimatedItem(index: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Informations Techniques', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: Spacing.lg),
                    Container(
                      padding: const EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(Spacing.radiusRound)),
                      child: Column(children: [
                        _buildInfoRow('Version', '1.0.0'),
                        Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
                        _buildInfoRow('Plateforme', 'Android / iOS'),
                        Divider(color: colorScheme.outline.withValues(alpha: 0.1)),
                        _buildInfoRow('Année', '${DateTime.now().year}'),
                      ]),
                    ),
                  ])),
                  const SizedBox(height: Spacing.xxxl),
                  Center(child: Text('© 2024 Panasoft Corporation', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double delay = index * 0.1;
        final double start = delay.clamp(0.0, 1.0);
        final double end = (delay + 0.6).clamp(0.0, 1.0);
        final animation = CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutCubic));

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: Padding(padding: const EdgeInsets.only(bottom: Spacing.lg), child: child),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.radiusRound),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.4), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(Spacing.radiusRound)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(Spacing.md), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Spacing.radiusMedium)), child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: Spacing.xs),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  void _showChangelog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: Spacing.xl),
            Row(children: [const Icon(Icons.auto_awesome, color: Colors.purple), const SizedBox(width: Spacing.md), const Text('Nouveautés 1.0.0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildChangelogItem(Icons.search, 'Recherche intelligente', 'Moteur de recherche fluide avec suggestions en temps réel.'),
                  _buildChangelogItem(Icons.folder_copy, 'Groupes d\'onglets', 'Organisez vos onglets par thématiques.'),
                  _buildChangelogItem(Icons.mic, 'Recherche vocale', 'Effectuez des recherches avec votre voix.'),
                  _buildChangelogItem(Icons.history, 'Historique local', 'Retrouvez vos anciennes recherches.'),
                  _buildChangelogItem(Icons.sync, 'Synchronisation Cloud', 'Synchronisez vos données sur tous vos appareils.'),
                  _buildChangelogItem(Icons.dark_mode, 'Interface moderne', 'Support du mode sombre et animations fluides.'),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Compris !'))),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelogItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(Spacing.md), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Spacing.radiusMedium)), child: Icon(icon, color: Colors.blue, size: 20)),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: Spacing.xs),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: Spacing.md),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(padding: EdgeInsets.all(Spacing.xl), child: Text('Questions fréquentes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                children: const [
                  FAQTile(question: 'Comment créer un groupe d\'onglets ?', answer: 'Menu principal → "Nouveau groupe". Une fois créé, activez-le pour y enregistrer automatiquement vos recherches.'),
                  FAQTile(question: 'Comment supprimer l\'historique ?', answer: 'Allez dans "Historique" → Vous pouvez supprimer chaque élément ou vider tout l\'historique.'),
                  FAQTile(question: 'Mes données sont-elles privées ?', answer: 'Oui, DjimSearch privilégie la confidentialité. Données stockées localement. Synchronisation cloud sécurisée.'),
                  FAQTile(question: 'Pourquoi la recherche vocale ne fonctionne pas ?', answer: 'Assurez-vous d\'avoir autorisé l\'accès au microphone dans les paramètres de votre téléphone.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aidez-nous à améliorer DjimSearch.'),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Décrivez le problème ici...',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci ! Votre rapport a été envoyé.'), behavior: SnackBarBehavior.floating));
          }, child: const Text('ENVOYER')),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nous Contacter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: Spacing.lg),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(Spacing.md), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.email_outlined, color: Colors.blue)),
              title: const Text('Email Support'),
              subtitle: const Text('support@panasoft.com'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(Spacing.md), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.language_rounded, color: Colors.green)),
              title: const Text('Site Web Officiel'),
              subtitle: const Text('www.panasoft-ca.com'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}

class FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const FAQTile({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Spacing.radiusRound), side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        childrenPadding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: [Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.5))],
      ),
    );
  }
}


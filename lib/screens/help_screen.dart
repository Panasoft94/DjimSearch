import 'package:flutter/material.dart';

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildAnimatedItem(
                    index: 0,
                    child: _buildFeatureCard(
                      icon: Icons.new_releases_rounded,
                      color: Colors.purple,
                      title: 'Nouveautés',
                      subtitle: 'Version 1.0.0 - Ce qui a changé',
                      onTap: () => _showChangelog(context),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 1,
                    child: _buildFeatureCard(
                      icon: Icons.help_outline_rounded,
                      color: Colors.blue,
                      title: 'Questions fréquentes',
                      subtitle: 'Réponses rapides à vos interrogations',
                      onTap: () => _showFAQ(context),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 2,
                    child: _buildFeatureCard(
                      icon: Icons.bug_report_rounded,
                      color: Colors.orange,
                      title: 'Signaler un problème',
                      subtitle: 'Aidez-nous à améliorer l\'application',
                      onTap: () => _showReportDialog(context),
                    ),
                  ),
                  _buildAnimatedItem(
                    index: 3,
                    child: _buildFeatureCard(
                      icon: Icons.alternate_email_rounded,
                      color: Colors.teal,
                      title: 'Nous contacter',
                      subtitle: 'Besoin d\'une assistance directe ?',
                      onTap: () => _showContactOptions(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildAnimatedItem(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informations Techniques',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('Version de l\'application', '1.0.0'),
                              const Divider(),
                              _buildInfoRow('Plateforme', 'Android / iOS'),
                              const Divider(),
                              _buildInfoRow('ID de session', '#DJM-${DateTime.now().year}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Panasoft Corporation © 2024',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
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
        
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showChangelog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 30),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 12),
                const Text('Nouveautés 1.0.0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildChangelogItem(Icons.search, 'Recherche intelligente', 'Intégration d\'un moteur de recherche fluide avec suggestions en temps réel.'),
                  _buildChangelogItem(Icons.folder_copy, 'Groupes d\'onglets', 'Organisez vos onglets par thématiques et enregistrez-les automatiquement.'),
                  _buildChangelogItem(Icons.mic, 'Recherche vocale', 'Utilisez votre voix pour effectuer des recherches rapidement.'),
                  _buildChangelogItem(Icons.history, 'Historique local', 'Retrouvez facilement vos anciennes recherches avec gestion individuelle.'),
                  _buildChangelogItem(Icons.sync, 'Synchronisation Cloud', 'Connectez-vous pour synchroniser vos données sur tous vos appareils.'),
                  _buildChangelogItem(Icons.dark_mode, 'Interface moderne', 'Support complet du mode sombre et animations fluides.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Compris !'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelogItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Questions fréquentes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _FAQTile(
                    question: 'Comment créer un groupe d\'onglets ?',
                    answer: 'Depuis le menu principal (⋮), choisissez "Nouveau groupe". Une fois créé, activez-le pour y enregistrer automatiquement vos prochaines recherches.',
                  ),
                  _FAQTile(
                    question: 'Comment supprimer l\'historique ?',
                    answer: 'Allez dans l\'écran "Historique" via le menu. Vous pouvez supprimer chaque élément individuellement ou vider tout l\'historique.',
                  ),
                  _FAQTile(
                    question: 'Mes données sont-elles privées ?',
                    answer: 'Oui, DjimSearch privilégie la confidentialité. Vos données sont stockées localement. La synchronisation cloud nécessite une connexion sécurisée.',
                  ),
                  _FAQTile(
                    question: 'Pourquoi la recherche vocale ne fonctionne pas ?',
                    answer: 'Assurez-vous d\'avoir autorisé l\'accès au microphone dans les paramètres de votre téléphone.',
                  ),
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
            const Text('Aidez-nous à améliorer DjimSearch en décrivant le bug rencontré.'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Décrivez le problème ici...',
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merci ! Votre rapport a été envoyé.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('ENVOYER'),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nous Contacter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.email_outlined, color: Colors.blue)),
              title: const Text('Email Support'),
              subtitle: const Text('support@panasoft.com'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.language_rounded, color: Colors.green)),
              title: const Text('Site Web Officiel'),
              subtitle: const Text('www.panasoft-ca.com'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        children: [
          Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}
